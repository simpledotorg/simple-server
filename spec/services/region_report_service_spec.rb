require "rails_helper"

RSpec.describe RegionReportService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:jan_2019) { Time.parse("January 1st, 2019") }
  let(:jan_2020) { Time.parse("January 1st, 2020") }
  let(:june_1) { Time.parse("June 1st, 2020") }
  let(:july_2020) { Time.parse("July 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "normalizes the selected_date" do
    period = Period.month(june_1)
    service = RegionReportService.new(region: facility_group_1, period: period, current_user: user)
    Timecop.freeze("June 30 2020 5:00 PM EST") do
      expect(service.selected_date).to eq(june_1.end_of_month.to_date)
    end
  end

  context "districts" do
    it "correctly returns controlled patients from three month window" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first
      facility_2 = create(:facility)

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: june_1, registration_facility: facility, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago, registration_facility: facility_2, registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end
        create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
      end

      Timecop.freeze(june_1) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end

        create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago)

        uncontrolled = create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, registration_user: user)
        uncontrolled.map do |patient|
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago)
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
        end
      end

      refresh_views

      service = RegionReportService.new(region: facility_group_1, period: Period.month(july_2020), current_user: user)
      result = service.call

      expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
      june_controlled = controlled_in_jan_and_june << controlled_just_for_june
      expect(result[:controlled_patients][Period.month(june_1)]).to eq(june_controlled.size)
    end

    fit "returns counts for last n months for controlled patients and registrations" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first

      old_patients = create_list(:patient, 2, recorded_at: jan_2019, registration_facility: facility, registration_user: user)
      old_patients.each do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: jan_2019)
      end

      Timecop.freeze(Time.parse("February 15th 2020")) do
        other_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
        other_patients.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        end
      end

      Timecop.freeze("April 15th 2020") do
        patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
        patients_with_controlled_bp.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current)
        end
      end

      refresh_views

      service = RegionReportService.new(region: facility_group_1, period: Period.month(june_1), current_user: user)
      result = service.call

      expected_controlled_patients = {
        "Jan 2019" => 2, "Feb 2019" => 2, "Mar 2019" => 2, "Feb 2020" => 2, "Mar 2020" => 2, "Apr 2020" => 4, "May 2020" => 2, "Jun 2020" => 2
      }
      expected_controlled_patients.default = 0
      expected_registrations = {
        "Dec 2018" => 0, "Jan 2020" => 4, "Feb 2020" => 4, "Mar 2020" => 6, "Apr 2020" => 6, "May 2020" => 6, "Jun 2020" => 6
      }
      expected_registrations.default = 2
      pp result
      expect(result[:controlled_patients].size).to eq(18)
      expect(result[:registrations].size).to eq(18)

      result[:controlled_patients].each do |month, count|
        expect(count).to eq(expected_controlled_patients[month]),
          "expected count for #{month} to be #{expected_controlled_patients[month]}, but was #{count}"
      end
      result[:registrations].each do |month, count|
        expect(count).to eq(expected_registrations[month]),
          "expected count for #{month} to be #{expected_registrations[month]}, but was #{count}"
      end
      expect(result[:cumulative_registrations]).to eq(6)
    end

    it "gets top district benchmarks" do
      darrang = FactoryBot.create(:facility_group, name: "Darrang", organization: organization)
      darrang_facilities = FactoryBot.create_list(:facility, 2, facility_group: darrang)
      kadapa = FactoryBot.create(:facility_group, name: "Kadapa", organization: organization)
      _kadapa_facilities = FactoryBot.create_list(:facility, 2, facility_group: kadapa)
      koriya = FactoryBot.create(:facility_group, name: "Koriya", organization: organization)
      koriya_facilities = FactoryBot.create_list(:facility, 2, facility_group: koriya)

      Timecop.freeze("April 1sth 2020") do
        darrang_patients = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: darrang_facilities.first, registration_user: user)
        darrang_patients.each do |patient|
          create(:blood_pressure, :hypertensive, facility: darrang_facilities.first, patient: patient, recorded_at: Time.current)
        end
      end
      Timecop.freeze("April 15th 2020") do
        patients_with_controlled_bp = create_list(:patient, 4, recorded_at: 1.month.ago, registration_facility: koriya_facilities.first, registration_user: user)
        patients_with_controlled_bp.map do |patient|
          create(:blood_pressure, :under_control, facility: koriya_facilities.first, patient: patient, recorded_at: Time.current)
        end
      end

      refresh_views

      service = RegionReportService.new(region: darrang, period: Period.month(june_1), current_user: user)
      result = service.call
      expect(result[:top_region_benchmarks][:control_rate][:value]).to eq(100.0)
      expect(result[:top_region_benchmarks][:control_rate][:region]).to eq(koriya)
    end

    it "can return data for quarters" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first
      facility_2 = create(:facility)

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: june_1, registration_facility: facility, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago, registration_facility: facility_2, registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end
        create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
      end

      Timecop.freeze(june_1) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end

        create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago)

        uncontrolled = create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, registration_user: user)
        uncontrolled.map do |patient|
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago)
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
        end
      end

      refresh_views

      service = RegionReportService.new(region: facility_group_1, period: Period.quarter(july_2020), current_user: user)
      result = service.call

      p result[:controlled_patients].keys
      pp result[:controlled_patients]
      expect(result[:controlled_patients].size).to eq(8)
      # expect(result[:controlled_patients][jan_2020.to_s(:month_year)]).to eq(controlled_in_jan_and_june.size)
      # june_controlled = controlled_in_jan_and_june << controlled_just_for_june
      # expect(result[:controlled_patients][june_1.to_s(:month_year)]).to eq(june_controlled.size)
    end
  end

  context "facilities" do
    it "returns control data and registrations" do
      facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
      facility, other_facility = facilities.first, facilities.last

      controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
      controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: june_1, registration_facility: facility, registration_user: user)
      patient_from_other_facility = create(:patient, full_name: "just for june", recorded_at: june_1, registration_facility: other_facility, registration_user: user)

      Timecop.freeze(jan_2020) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end
        create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
        create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility,
                                                recorded_at: 2.days.ago, user: user)
      end

      Timecop.freeze(june_1) do
        controlled_in_jan_and_june.map do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago)
        end

        create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago)

        uncontrolled = create_list(:patient, 2, recorded_at: Time.current, registration_facility: facility, registration_user: user)
        uncontrolled.map do |patient|
          create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago)
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago)
        end
      end

      refresh_views

      service = RegionReportService.new(region: facility, period: Period.month(july_2020), current_user: user)
      result = service.call

      expect(result[:controlled_patients][jan_2020.to_s(:month_year)]).to eq(controlled_in_jan_and_june.size)
      expect(result[:controlled_patients_rate][jan_2020.to_s(:month_year)]).to eq(100)
      expect(result[:registrations][jan_2020.to_s(:month_year)]).to eq(2)
      june_controlled = controlled_in_jan_and_june << controlled_just_for_june
      expect(result[:controlled_patients][june_1.to_s(:month_year)]).to eq(june_controlled.size)
      expect(result[:controlled_patients_rate][june_1.to_s(:month_year)]).to eq(60.0)
      expect(result[:registrations][june_1.to_s(:month_year)]).to eq(5)
    end
  end
end
