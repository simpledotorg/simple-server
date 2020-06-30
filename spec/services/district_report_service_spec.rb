require "rails_helper"

describe DistrictReportService, type: :model do
  let(:user) { create(:user) }
  let(:june_1) { Time.parse("June 1, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "correctly returns controlled patients from three month window" do
    facility_group = FactoryBot.create(:facility_group, name: "Darrang")
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group)
    facility = facilities.first
    facility_2 = create(:facility)

    jan_1 = Time.parse("January 1st, 2020")

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: Time.current, registration_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago, registration_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_1) do
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

    service = DistrictReportService.new(facilities: facility_group.facilities, selected_date: june_1)
    expect(service.controlled_patients_count(jan_1)).to eq(controlled_in_jan_and_june.size)
    june_controlled = controlled_in_jan_and_june << controlled_just_for_june
    expect(service.controlled_patients_count(june_1)).to eq(june_controlled.size)
  end

  it "returns counts for last n months for controlled patients and registrations" do
    facility_group = FactoryBot.create(:facility_group, name: "Darrang")
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group)
    facility = facilities.first

    jan_2019 = Time.parse("January 1st 2019")
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

    service = DistrictReportService.new(facilities: facility_group.facilities, selected_date: june_1)
    result = service.call

    expected_controlled_patients = {
      "Jan 2019" => 2, "Feb 2019" => 2, "Mar 2019" => 2, "Feb 2020" => 2, "Mar 2020" => 2, "Apr 2020" => 4, "May 2020" => 2, "Jun 2020" => 2
    }
    expected_controlled_patients.default = 0
    expected_registrations = {
      "Jan 2020" => 4, "Feb 2020" => 4, "Mar 2020" => 6, "Apr 2020" => 6, "May 2020" => 6, "Jun 2020" => 6
    }
    expected_registrations.default = 2
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

  it "gets top district" do
    darrang = FactoryBot.create(:facility_group, name: "Darrang")
    darrang_facilities = FactoryBot.create_list(:facility, 2, facility_group: darrang)
    kadapa = FactoryBot.create(:facility_group, name: "Kadapa")
    kadapa_facilities = FactoryBot.create_list(:facility, 2, facility_group: kadapa)
    koriya = FactoryBot.create(:facility_group, name: "Koriya")
    koriya_facilities = FactoryBot.create_list(:facility, 2, facility_group: koriya)

    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 4, recorded_at: 1.month.ago, registration_facility: koriya_facilities.first, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: koriya_facilities.first, patient: patient, recorded_at: Time.current)
      end
    end

    refresh_views

    service = DistrictReportService.new(facilities: darrang.facilities, selected_date: june_1)
    result = service.call
    expect(result[:top_district_benchmarks][:district]).to eq("Koriya")
    expect(result[:top_district_benchmarks][:controlled_percentage]).to eq(100.0)
  end
end
