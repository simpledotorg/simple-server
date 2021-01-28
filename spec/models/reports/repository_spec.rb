require "rails_helper"

RSpec.describe Reports::Repository, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1_2018) { Time.parse("June 1, 2018 00:00:00+00:00") }
  let(:june_1_2020) { Time.parse("June 1, 2020 00:00:00+00:00") }
  let(:june_30_2020) { Time.parse("June 30, 2020 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 15, 2020 00:00:00+00:00") }
  let(:jan_2019) { Time.parse("January 1st, 2019 00:00:00+00:00") }
  let(:jan_2020) { Time.parse("January 1st, 2020 00:00:00+00:00") }
  let(:july_2018) { Time.parse("July 1st, 2018 00:00:00+00:00") }
  let(:july_2020) { Time.parse("July 1st, 2020 00:00:00+00:00") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  fit "gets controlled info for one month" do
    facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1).sort_by(&:slug)
    facility_1 = facilities[0]
    facility_2 = facilities[1]
    facility_3 = facilities[2]

    controlled_in_jan = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan.map do |patient|
        create(:blood_pressure, :under_control, facility: facility_1, patient: patient, recorded_at: 35.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility_2, patient: patient, recorded_at: 35.days.ago, user: user)
      end
      uncontrolled_in_jan.map { |patient| create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago) }
      create(:blood_pressure, :under_control, facility: facility_3, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    refresh_views

    regions = facilities.map(&:region)
    repo = Reports::Repository.new(regions, periods: Period.month(jan_2020))
    result = repo.controlled_patients_info
    pp result
  end

  it "correctly returns controlled patients for past months" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
    uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled_in_jan.map { |patient| create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago) }
      create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    Timecop.freeze(june_1_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 35.days.ago, user: user)
      end

      create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

      # register 5 more patients in feb 2020
      uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, assigned_facility: facility, registration_user: user)
      uncontrolled_in_june.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago, user: user)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    start_range = july_2020.advance(months: -24)
    service = ControlRateService.new(facility_group_1, periods: (Period.month(start_range)..Period.month(july_2020)))
    result = service.call

    expect(result[:registrations][Period.month(jan_2019)]).to eq(5)
    expect(result[:cumulative_registrations][Period.month(jan_2019)]).to eq(5)
    expect(result[:adjusted_registrations][Period.month(jan_2019)]).to eq(0)

    expect(result[:cumulative_registrations][Period.month(jan_2020)]).to eq(5)
    expect(result[:adjusted_registrations][Period.month(jan_2020)]).to eq(5)
    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(40.0)

    # 3 controlled patients in june and 10 cumulative registered patients
    expect(result[:cumulative_registrations][Period.month(june_1_2020)]).to eq(10)
    expect(result[:registrations][Period.month(june_1_2020)]).to eq(0)
    expect(result[:controlled_patients][Period.month(june_1_2020)]).to eq(3)
    expect(result[:controlled_patients_rate][Period.month(june_1_2020)]).to eq(30.0)
    expect(result[:uncontrolled_patients][Period.month(june_1_2020)]).to eq(5)
    expect(result[:uncontrolled_patients_rate][Period.month(june_1_2020)]).to eq(50.0)
  end
end
