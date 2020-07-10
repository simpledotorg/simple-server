require "rails_helper"

RSpec.describe ControlRateService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_2018) { Time.parse("June 1, 2018") }
  let(:june_1) { Time.parse("June 1, 2020") }
  let(:june_30_2020) { Time.parse("June 30, 2020") }
  let(:jan_2019) { Time.parse("January 1st, 2019") }
  let(:jan_2020) { Time.parse("January 1st, 2020") }
  let(:july_2020) { Time.parse("July 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "does not include months without registration data" do
    facility = FactoryBot.create(:facility, facility_group: facility_group_1)
    Timecop.freeze("April 15th 2020") do
      patients_with_controlled_bp = create_list(:patient, 2, recorded_at: 1.month.ago, registration_facility: facility, registration_user: user)
      patients_with_controlled_bp.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.current, user: user)
      end
    end

    refresh_views

    range = (june_2018..june_30_2020)
    result = nil
    Timecop.freeze("July 1st 2020") do
      service = ControlRateService.new(facility_group_1, range: range)
      result = service.call
    end
    # registrations from March, Apr, May, June
    expect(result[:controlled_patients].size).to eq(4)
    expect(result[:registrations].size).to eq(4)
  end

  it "correctly returns controlled patients from three month window" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago, registration_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled.map { |patient| create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago) }
      create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    Timecop.freeze(june_1) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end

      create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

      uncontrolled = create_list(:patient, 5, recorded_at: Time.current, registration_facility: facility, registration_user: user)
      uncontrolled.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago, user: user)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    start_range = july_2020.advance(months: -24)
    service = ControlRateService.new(facility_group_1, range: (start_range..july_2020))
    result = service.call

    expect(result[:controlled_patients][jan_2020.to_s(:month_year)]).to eq(controlled_in_jan_and_june.size)
    expect(result[:controlled_patients_rate][jan_2020.to_s(:month_year)]).to eq(50.0)

    # 3 controlled patients in june and 9 cumulative registered patients
    june_1_key = june_1.to_s(:month_year)
    expect(result[:controlled_patients][june_1_key]).to eq(3)
    expect(result[:registrations][june_1_key]).to eq(9)
    expect(result[:controlled_patients_rate][june_1_key]).to eq(33.3)
  end

  it "returns control rate for a single facility" do
    facilities = FactoryBot.create_list(:facility, 2, facility_group: facility_group_1)
    facility = facilities.first

    controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020,
                                          registration_facility: facility, registration_user: user)
    uncontrolled = create_list(:patient, 4, full_name: "uncontrolled", recorded_at: jan_2020,
                                            registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago,
                                                   registration_facility: facilities.last, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility,
                                               patient: patient, recorded_at: 4.days.ago, user: user)
      end
      create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility,
                                              recorded_at: 2.days.ago, user: user)
    end

    refresh_views

    start_range = july_2020.advance(months: -24)
    service = ControlRateService.new(facility, range: (start_range..july_2020))
    result = service.call

    expect(result[:controlled_patients][jan_2020.to_s(:month_year)]).to eq(controlled.size)
    expect(result[:registrations][jan_2020.to_s(:month_year)]).to eq(6)
    expect(result[:controlled_patients_rate][jan_2020.to_s(:month_year)]).to eq(33.3)
  end
end
