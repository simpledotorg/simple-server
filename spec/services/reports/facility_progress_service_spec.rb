require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:seven_days_ago) { 7.days.ago }
  let(:two_days_ago) { 2.days.ago }
  let(:one_day_ago) { 1.day.ago }
  let(:two_minutes_ago) { 2.minutes.ago }

  context "daily registrations" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      facility = create(:facility, enable_diabetes_management: true)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        refresh_views
        service = described_class.new(facility, Period.current)
        expect(service.daily_registrations(3.days.ago.to_date)).to eq(3)
        expect(service.daily_registrations(1.days.ago.to_date)).to eq(0)
        expect(service.daily_registrations(Date.current)).to eq(1)
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      skip "time zone issues in CI"
      facility = create(:facility, enable_diabetes_management: false)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      with_reporting_time_zone do
        refresh_views
        service = described_class.new(facility, Period.current)
        expect(service.daily_registrations(3.days.ago)).to eq(2)
        expect(service.daily_registrations(1.days.ago)).to eq(0)
        expect(service.daily_registrations(Date.current)).to eq(1)
      end
    end
  end

  context "daily follow up counts" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      Timecop.freeze do
        facility = create(:facility, enable_diabetes_management: true)
        patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient3 = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        patient4 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        one_day_ago # ensure this is set to UTC time zone
        create(:appointment, recorded_at: two_days_ago, patient: patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient3, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: patient4, facility: facility, user: user)
        with_reporting_time_zone do
          refresh_views
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(two_days_ago.to_date)).to eq(3)
          expect(service.daily_follow_ups(one_day_ago.to_date)).to eq(0)
        end
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      Timecop.freeze do
        facility = create(:facility, enable_diabetes_management: false)
        htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        undiagnosed_patient = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        one_day_ago # ensure this is set to UTC time zone
        create(:appointment, recorded_at: seven_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: two_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: htn_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: dm_patient, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient, facility: facility, user: user)

        with_reporting_time_zone do
          refresh_views
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(seven_days_ago.to_date)).to eq(1)
          expect(service.daily_follow_ups(two_days_ago.to_date)).to eq(2)
          expect(service.daily_follow_ups(one_day_ago.to_date)).to eq(0)
          expect(service.daily_follow_ups(Date.current)).to eq(0)
        end
      end
    end

    it "includes data from current day for follow up numbers" do
      Timecop.freeze(Date.today.at_noon) do
        facility = create(:facility, enable_diabetes_management: true)
        htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        undiagnosed_patient = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        create(:appointment, recorded_at: seven_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: two_minutes_ago, patient: htn_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: htn_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_minutes_ago, patient: dm_patient, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient, facility: facility, user: user)

        with_reporting_time_zone do
          refresh_views
          service = described_class.new(facility, Period.current)
          expect(service.daily_follow_ups(Date.current)).to eq(3)
        end
      end
    end
  end
end
