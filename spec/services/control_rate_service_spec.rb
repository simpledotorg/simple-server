require "rails_helper"

RSpec.describe ControlRateService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :supervisor, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_2018) { Time.parse("June 1, 2018") }
  let(:june_1) { Time.parse("June 1, 2020") }
  let(:june_30_2020) { Time.parse("June 30, 2020") }
  let(:july_2020) { Time.parse("July 15, 2020") }
  let(:jan_2019) { Time.parse("January 1st, 2019") }
  let(:jan_2020) { Time.parse("January 1st, 2020") }
  let(:july_2018) { Time.parse("July 1st, 2018") }
  let(:july_2020) { Time.parse("July 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      LatestBloodPressuresPerPatientPerQuarter.refresh
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

    range = (Period.month(june_2018)..Period.month(june_30_2020))
    result = nil
    Timecop.freeze("July 1st 2020") do
      service = ControlRateService.new(facility_group_1, periods: range)
      result = service.call
    end
    # registrations from March, Apr, May, June
    expect(result[:controlled_patients].size).to eq(4)
    expect(result[:registrations].size).to eq(4)
  end

  it "correctly returns controlled patients for past months" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: 8.months.ago, registration_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled_in_jan.map { |patient| create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago) }
      create(:blood_pressure, :under_control, facility: facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    Timecop.freeze(june_1) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 4.days.ago, user: user)
      end

      create(:blood_pressure, :under_control, facility: facility, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

      uncontrolled_in_june = create_list(:patient, 5, recorded_at: 7.days.ago, registration_facility: facility, registration_user: user)
      uncontrolled_in_june.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: 1.days.ago, user: user)
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    start_range = july_2020.advance(months: -24)
    service = ControlRateService.new(facility_group_1, periods: (Period.month(start_range)..Period.month(july_2020)))
    result = service.call

    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(40.0)

    # 3 controlled patients in june and 10 cumulative registered patients
    june_1_key = june_1.to_s(:month_year)
    expect(result[:registrations][Period.month(june_1_key)]).to eq(10)
    expect(result[:controlled_patients][Period.month(june_1_key)]).to eq(3)
    expect(result[:controlled_patients_rate][Period.month(june_1_key)]).to eq(30.0)
    expect(result[:uncontrolled_patients][Period.month(june_1_key)]).to eq(5)
    expect(result[:uncontrolled_patients_rate][Period.month(june_1_key)]).to eq(50.0)
  end

  it "quarterly control rate looks only at patients registered in the previous quarter" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_q1 = create_list(:patient, 3, recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    controlled_in_q1.each do |patient|
      create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
    end

    controlled_in_q3 = create_list(:patient, 3, recorded_at: june_1, registration_facility: facility, registration_user: user)
    controlled_in_q3.each do |patient|
      create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
    end

    controlled_in_q3_other_facility = create_list(:patient, 3, recorded_at: june_1, registration_facility: facility_2, registration_user: user)
    controlled_in_q3_other_facility.each do |patient|
      create(:blood_pressure, :under_control, facility: facility_2, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
    end

    uncontrolled_in_q3 = create_list(:patient, 7, recorded_at: june_1, registration_facility: facility, registration_user: user)
    uncontrolled_in_q3.each do |patient|
      create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
    end

    refresh_views

    periods = Period.quarter(july_2018)..Period.quarter(july_2020)
    service = ControlRateService.new(facility_group_1, periods: periods)
    result = service.call

    # expect(result[:registrations].keys.size).to eq(3) # 3 quarters of data
    # expect(result[:registrations].keys.first.to_s).to eq("Q1-2020")
    # expect(result[:registrations].keys.last.to_s).to eq("Q3-2020")

    q3_2020 = Period.quarter("Q3-2020")
    # expect(result[:registrations][q3_2020]).to eq(10)
    expect(result[:controlled_patients][q3_2020]).to eq(3)
    expect(result[:controlled_patients_rate][q3_2020]).to eq(30.0)
    expect(result[:uncontrolled_patients][q3_2020]).to eq(7)
    expect(result[:uncontrolled_patients_rate][q3_2020]).to eq(70.0)
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

    periods = Period.month(july_2018)..Period.month(july_2020)
    service = ControlRateService.new(facility, periods: periods)
    result = service.call

    expect(result[:controlled_patients][Period.month(jan_2020)]).to eq(controlled.size)
    expect(result[:registrations][Period.month(jan_2020)]).to eq(6)
    expect(result[:controlled_patients_rate][Period.month(jan_2020)]).to eq(33.3)
  end

  it "has a reasonable cache key" do
    periods = Period.month(july_2018)..Period.month(july_2020)
    service = ControlRateService.new(facility_group_1, periods: periods)
    expected_key = "ControlRateService/FacilityGroup/#{facility_group_1.id}/month_periods/#{july_2018.to_date}/#{july_2020.to_date}"
    expect(service.send(:cache_key)).to eq(expected_key)
  end
end
