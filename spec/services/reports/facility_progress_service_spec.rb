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

    context "diabetes reports" do
      it "returns the correct diabetes report data" do
        facility = create(:facility, enable_diabetes_management: true)
        dm_patients = create_list(:patient, 2, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
        dm_patients.each do |patient|
          create(:blood_sugar, patient: patient, facility: facility, recorded_at: 2.month.ago)
          create(:blood_sugar, patient: patient, facility: facility, recorded_at: 1.month.ago)
          create(:blood_sugar, patient: patient, facility: facility, recorded_at: Date.current)
        end
        refresh_views
        service = described_class.new(facility, Period.current)
        result = service.diabetes_reports_data
        current_month = Date.current.beginning_of_month
        previous_month = current_month - 1.month
        two_months_ago = current_month - 2.months
        expected_period_info = [two_months_ago, previous_month, current_month].map do |month|
          [
            Period.new(type: :month, value: month.strftime("%Y-%m-01")),
            {
              bp_control_end_date: month.end_of_month.strftime("%d-%b-%Y"),
              bp_control_registration_date: (month - 3.months).end_of_month.strftime("%d-%b-%Y"),
              bp_control_start_date: (month - 2.months).beginning_of_month.strftime("%-d-%b-%Y"),
              ltfu_end_date: month.end_of_month.strftime("%d-%b-%Y"),
              ltfu_since_date: (month - 1.year).end_of_month.strftime("%d-%b-%Y"),
              name: month.strftime("%b-%Y")
            }
          ]
        end.to_h
        expected_follow_ups = {
          Period.month(two_months_ago) => 0,
          Period.month(previous_month) => dm_patients.count,
          Period.month(current_month) => dm_patients.count
        }
        expect(result).to include(:assigned_patients, :period_info, :region, :total_registrations, :monthly_follow_ups, :missed_visits, :missed_visits_rates, :adjusted_patients)
        expect(result[:assigned_patients]).to eq(dm_patients.count)
        expect(result[:period_info]).to eq(expected_period_info)
        expect(result[:monthly_follow_ups]).to eq(expected_follow_ups)
      end
    end
  end
end
