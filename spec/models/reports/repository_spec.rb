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

  it "gets controlled info for one month" do
    facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1).sort_by(&:slug)
    facility_1, facility_2, facility_3 = *facilities.take(3)
    regions = facilities.map(&:region)

    facility_1_controlled = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_1_uncontrolled = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    facility_2_controlled = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)

    Timecop.freeze(jan_2020) do
      (facility_1_controlled << facility_2_controlled).map do |patient|
        create(:blood_pressure, :under_control, facility: facility_1, patient: patient, recorded_at: 15.days.ago, user: user)
      end
      facility_1_uncontrolled.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 15.days.ago)
      end
    end

    refresh_views

    jan = Period.month(jan_2020)
    repo = Reports::Repository.new(regions, periods: Period.month(jan))
    controlled = repo.controlled_patients_count
    uncontrolled = repo.uncontrolled_patients_count
    expect(controlled["facility-1"].fetch(jan)).to eq(2)
    expect(controlled["facility-2"].fetch(jan)).to eq(1)
    expect(controlled["facility-3"].fetch(jan)).to eq(0)
    expect(uncontrolled["facility-1"].fetch(jan)).to eq(2)
    expect(uncontrolled["facility-2"].fetch(jan)).to eq(0)
    expect(uncontrolled["facility-3"].fetch(jan)).to eq(0)
  end

  it "gets controlled info for range of month periods" do
    facilities = FactoryBot.create_list(:facility, 3, facility_group: facility_group_1)
    facility_1, facility_2, facility_3 = *facilities.take(3)
    regions = facilities.map(&:region)

    controlled_in_jan_and_june = create_list(:patient, 2, full_name: "controlled", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    uncontrolled_in_jan = create_list(:patient, 2, full_name: "uncontrolled", recorded_at: jan_2019, assigned_facility: facility_2, registration_user: user)
    controlled_just_for_june = create(:patient, full_name: "just for june", recorded_at: jan_2019, assigned_facility: facility_1, registration_user: user)
    patient_from_other_facility = create(:patient, full_name: "other facility", recorded_at: jan_2019, assigned_facility: create(:facility), registration_user: user)

    Timecop.freeze(jan_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago, user: user)
      end
      uncontrolled_in_jan.map { |patient| create(:blood_pressure, :hypertensive, facility: facility_2, patient: patient, recorded_at: 4.days.ago) }
      create(:blood_pressure, :under_control, facility: patient_from_other_facility.assigned_facility, patient: patient_from_other_facility, recorded_at: 2.days.ago)
    end

    Timecop.freeze(june_1_2020) do
      controlled_in_jan_and_june.map do |patient|
        create(:blood_pressure, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 4.days.ago, user: user)
        create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 35.days.ago, user: user)
      end

      create(:blood_pressure, :under_control, facility: facility_3, patient: controlled_just_for_june, recorded_at: 4.days.ago, user: user)

      uncontrolled_in_june = create_list(:patient, 5, recorded_at: 4.months.ago, assigned_facility: facility_1, registration_user: user)
      uncontrolled_in_june.map do |patient|
        create(:blood_pressure, :hypertensive, facility: facility_1, patient: patient, recorded_at: 1.days.ago, user: user)
        create(:blood_pressure, :under_control, facility: facility_1, patient: patient, recorded_at: 2.days.ago, user: user)
      end
    end

    refresh_views

    start_range = july_2020.advance(months: -24)
    range = (Period.month(start_range)..Period.month(july_2020))
    repo = Reports::Repository.new(regions, periods: range)
    result = repo.controlled_patients_count

    facility_1_results = result[facility_1.slug]
    expect(facility_1_results[Period.month(jan_2020)]).to eq(controlled_in_jan_and_june.size)
    expect(facility_1_results[Period.month(june_1_2020)]).to eq(3)
  end
end
