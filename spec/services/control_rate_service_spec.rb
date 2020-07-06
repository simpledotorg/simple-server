require "rails_helper"

RSpec.describe ControlRateService, type: :model do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) do
    create(:admin, :supervisor, organization: organization).tap do |user|
      user.user_permissions << build(:user_permission, permission_slug: :view_cohort_reports, resource: organization)
    end
  end
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }

  let(:june_1) { Time.parse("June 1, 2020") }
  let(:june_30_2020) { Time.parse("June 30, 2020") }
  let(:jan_2019) { Time.parse("January 1st, 2019") }
  let(:jan_2020) { Time.parse("January 1st, 2020") }

  def refresh_views
    ActiveRecord::Base.transaction do
      LatestBloodPressuresPerPatientPerMonth.refresh
      PatientRegistrationsPerDayPerFacility.refresh
    end
  end

  it "correctly returns controlled patients from three month window" do
    facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
    facility = facilities.first
    facility_2 = create(:facility)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2020, registration_facility: facility, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", registration_facility: facility, registration_user: user)
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

    july_2020 = Time.parse("July 1st, 2020")
    start_range = july_2020.advance(months: -24)
    service = ControlRateService.new(facility_group_1, range: (start_range..july_2020))
    result = service.call

    p result[:controlled_patients]
    p result[:controlled_patients].size

    expect(result[:controlled_patients][jan_2020.to_s(:month_year)]).to eq(controlled_in_jan_and_june.size)

    june_controlled = controlled_in_jan_and_june << controlled_just_for_june
    expect(result[:controlled_patients][june_1.to_s(:month_year)]).to eq(june_controlled.size)
  end
end