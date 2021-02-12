require "rails_helper"

RSpec.describe ControlRateQuery do
  let(:organization) { create(:organization, name: "org-1") }
  let(:user) { create(:admin, :manager, :with_access, resource: organization, organization: organization) }
  let(:facility_group_1) { FactoryBot.create(:facility_group, name: "facility_group_1", organization: organization) }
  let(:query) { ControlRateQuery.new }

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

  context "monthly period" do
    it "returns counts for passed in periods" do
      facility = FactoryBot.create(:facility, facility_group: facility_group_1)
      patients = [
        create(:patient, recorded_at: jan_2019, assigned_facility: facility, registration_user: user),
        create(:patient, status: :dead, recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
      ]

      Timecop.freeze(june_1_2020) do
        patients.each do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        end
      end

      refresh_views

      may = query.controlled(facility_group_1, Period.month("May 1 2020")).count
      june = query.controlled(facility_group_1, june_1_2020.to_period).count
      august = query.controlled(facility_group_1, Period.month("August 1 2020")).count
      july = query.controlled(facility_group_1, Period.month("July 1 2020")).count

      expect(may).to eq(2)
      expect(june).to eq(2)
      expect(july).to eq(2)
      expect(august).to eq(0)
    end

    it "excludes patients who are dead when with_exclusions is true" do
      facility = FactoryBot.create(:facility, facility_group: facility_group_1)
      patients = [
        create(:patient, recorded_at: jan_2019, assigned_facility: facility, registration_user: user),
        create(:patient, status: :dead, recorded_at: jan_2019, assigned_facility: facility, registration_user: user)
      ]

      Timecop.freeze(june_1_2020) do
        patients.each do |patient|
          create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: 2.days.ago, user: user)
        end
      end

      refresh_views

      may = query.controlled(facility_group_1, Period.month("May 1 2020"), with_exclusions: true).count
      june = query.controlled(facility_group_1, june_1_2020.to_period, with_exclusions: true).count
      august = query.controlled(facility_group_1, Period.month("August 1 2020"), with_exclusions: true).count
      july = query.controlled(facility_group_1, Period.month("July 1 2020"), with_exclusions: true).count

      expect(may).to eq(1)
      expect(june).to eq(1)
      expect(july).to eq(1)
      expect(august).to eq(0)
    end
  end

  context "quarterly period" do
    it "returns counts for patients registered in the previous quarter" do
      facilities = FactoryBot.create_list(:facility, 5, facility_group: facility_group_1)
      facility = facilities.first
      facility_2 = create(:facility)

      controlled_in_q1 = create_list(:patient, 3, recorded_at: jan_2020, assigned_facility: facility, registration_user: user)
      controlled_in_q1.each do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
      end

      controlled_in_q3 = create_list(:patient, 3, recorded_at: june_1_2020, assigned_facility: facility, registration_user: user)
      controlled_in_q3.each do |patient|
        create(:blood_pressure, :under_control, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
      end

      controlled_in_q3_other_facility = create_list(:patient, 3, recorded_at: june_1_2020, assigned_facility: facility_2, registration_user: user)
      controlled_in_q3_other_facility.each do |patient|
        create(:blood_pressure, :under_control, facility: facility_2, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
      end

      uncontrolled_in_q3 = create_list(:patient, 6, recorded_at: june_1_2020, assigned_facility: facility, registration_user: user)
      uncontrolled_in_q3.each do |patient|
        create(:blood_pressure, :hypertensive, facility: facility, patient: patient, recorded_at: Time.parse("September 1 2020"), user: user)
      end

      refresh_views

      q3_2020 = Period.quarter("Q3-2020")
      q4_2020 = Period.quarter("Q4-2020")
      expect(query.controlled(facility_group_1, q3_2020).count).to eq(3)
      expect(query.controlled(facility_group_1, q4_2020).count).to eq(0)

      expect(query.uncontrolled(facility_group_1, q3_2020).count).to eq(6)
      expect(query.uncontrolled(facility_group_1, q4_2020).count).to eq(0)
    end
  end
end
