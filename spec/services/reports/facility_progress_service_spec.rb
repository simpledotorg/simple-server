require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  around do |example|
    with_reporting_time_zone { example.run }
  end

  let(:user) { create(:user) }
  let(:facility) { create(:facility) }
  let(:seven_days_ago) { 7.days.ago }
  let(:two_days_ago) { 2.days.ago }
  let(:one_day_ago) { 1.day.ago }
  let(:two_minutes_ago) { 2.minutes.ago }
  let(:region) { double("Region", name: "Region 1") }

  context "daily registrations" do
    it "returns counts for HTN or DM patients if diabetes is enabled" do
      facility = create(:facility, enable_diabetes_management: true)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      refresh_views
      service = described_class.new(facility, Period.current)

      expect(service.daily_registrations(3.days.ago.to_date)).to eq(3)
      expect(service.daily_registrations(1.days.ago.to_date)).to eq(0)
      expect(service.daily_registrations(Date.current)).to eq(1)
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      facility = create(:facility, enable_diabetes_management: false)
      _htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 3.days.ago)
      _htn_patient3 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 1.minute.ago)

      refresh_views
      service = described_class.new(facility, Period.current)

      expect(service.daily_registrations(3.days.ago.to_date)).to eq(2)
      expect(service.daily_registrations(1.days.ago.to_date)).to eq(0)
      expect(service.daily_registrations(Date.current)).to eq(1)
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
        one_day_ago
        create(:appointment, recorded_at: two_days_ago, patient: patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: patient3, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: patient4, facility: facility, user: user)

        refresh_views
        service = described_class.new(facility, Period.current)

        expect(service.daily_follow_ups(two_days_ago.to_date)).to eq(3)
        expect(service.daily_follow_ups(one_day_ago.to_date)).to eq(0)
      end
    end

    it "returns counts for HTN only if diabetes is not enabled" do
      Timecop.freeze do
        facility = create(:facility, enable_diabetes_management: false)
        htn_patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        htn_patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        undiagnosed_patient = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        one_day_ago
        create(:appointment, recorded_at: seven_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: two_days_ago, patient: htn_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: htn_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_days_ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_days_ago, patient: dm_patient, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient, facility: facility, user: user)

        refresh_views
        service = described_class.new(facility, Period.current)
        expect(service.daily_follow_ups(seven_days_ago.to_date)).to eq(1)
        expect(service.daily_follow_ups(two_days_ago.to_date)).to eq(2)
        expect(service.daily_follow_ups(one_day_ago.to_date)).to eq(0)
        expect(service.daily_follow_ups(Date.current)).to eq(0)
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

        refresh_views
        service = described_class.new(facility, Period.current)

        expect(service.daily_follow_ups(Date.current)).to eq(3)
      end
    end

    it "includes the region, assigned patients, total registration and period info" do
      Timecop.freeze(Date.today.at_noon) do
        facility = create(:facility, enable_diabetes_management: true)
        dm_patient1 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient2 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        undiagnosed_patient = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patient3 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)

        create(:appointment, recorded_at: seven_days_ago, patient: dm_patient1, facility: facility, user: user)
        create(:appointment, recorded_at: two_minutes_ago, patient: dm_patient1, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient2, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: undiagnosed_patient, facility: facility, user: user)
        create(:blood_sugar, recorded_at: two_minutes_ago, patient: dm_patient3, facility: facility, user: user)
        create(:blood_pressure, recorded_at: two_minutes_ago, patient: dm_patient3, facility: facility, user: user)

        refresh_views
        service = described_class.new(facility, Period.current)
        result = service.diabetes_reports_data
        expect(result).to include(:assigned_patients, :period_info, :region, :total_registrations)
        expected_period_info = {
          Period.new(type: :month, value: '2024-09-01') => {
            :bp_control_end_date => "30-Sep-2024", 
            :bp_control_registration_date => "30-Jun-2024", 
            :bp_control_start_date => "1-Jul-2024", 
            :ltfu_end_date => "30-Sep-2024", 
            :ltfu_since_date => "30-Sep-2023", 
            :name => "Sep-2024"
          },
          Period.new(type: :month, value: '2024-10-01') => {
            :bp_control_end_date => "31-Oct-2024", 
            :bp_control_registration_date => "31-Jul-2024", 
            :bp_control_start_date => "1-Aug-2024", 
            :ltfu_end_date => "31-Oct-2024", 
            :ltfu_since_date => "31-Oct-2023", 
            :name => "Oct-2024"
          },
          Period.new(type: :month, value: '2024-11-01') => {
            :bp_control_end_date => "30-Nov-2024", 
            :bp_control_registration_date => "31-Aug-2024", 
            :bp_control_start_date => "1-Sep-2024", 
            :ltfu_end_date => "30-Nov-2024", 
            :ltfu_since_date => "30-Nov-2023", 
            :name => "Nov-2024"
          }
        }
        expect(result[:period_info]).to eq(expected_period_info)
      end
    end
  end
end
