require "rails_helper"

RSpec.describe Reports::FacilityMonthlyFollowUpAndRegistration, {type: :model, reporting_spec: true} do
  let(:user) { create(:user) }
  let(:user_2) { create(:user) }
  let(:facility) { create(:facility) }

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  it "does not contain discarded patients" do
    six_months_ago = june_2021[:six_months_ago]
    patient = create(:patient, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: six_months_ago)
    patient.discard
    RefreshReportingViews.call
    result = described_class.find_by(facility: facility, month_date: six_months_ago.to_date)
    expect(result.monthly_registrations_htn_or_dm).to eq(0)
    expect(result.monthly_follow_ups_htn_or_dm).to eq(0)
  end

  it "patients without a medical history are not included" do
    six_months_ago = june_2021[:six_months_ago]
    patient = create(:patient, :without_medical_history, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: six_months_ago)
    RefreshReportingViews.call
    result = described_class.find_by(facility: facility, month_date: six_months_ago.to_date)
    expect(result.monthly_registrations_htn_or_dm).to eq(0)
    expect(result.monthly_follow_ups_htn_or_dm).to eq(0)
  end

  context "totals" do
    it "can sum registrations for all the count fields for all time totals" do
      two_years_ago, six_months_ago = june_2021.values_at(:two_years_ago, :six_months_ago)
      create_list(:patient, 2, :hypertension, recorded_at: two_years_ago, gender: :female, registration_user: user, registration_facility: facility)
      create_list(:patient, 2, :hypertension, recorded_at: six_months_ago, gender: :female, registration_user: user, registration_facility: facility)
      create_list(:patient, 3, :hypertension, recorded_at: two_years_ago, gender: :male, registration_user: user, registration_facility: facility)
      create_list(:patient, 1, :hypertension, recorded_at: two_years_ago, gender: :transgender, registration_user: user, registration_facility: facility)
      refresh_views
      total = described_class.totals(facility)
      expect(total.monthly_registrations_htn_or_dm).to eq(8)
      expect(total.monthly_registrations_htn_only).to eq(8)
      expect(total.monthly_registrations_htn_only_male).to eq(3)
      expect(total.monthly_registrations_htn_only_female).to eq(4)
      expect(total.monthly_registrations_htn_only_transgender).to eq(1)
    end

    it "can sum follow_ups for all count fields for all time totals" do
      two_years_ago, six_months_ago = june_2021.values_at(:two_years_ago, :six_months_ago)
      patient_1 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: :female, registration_user: user, registration_facility: facility)
      patient_2 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: :female, registration_user: user, registration_facility: facility)
      patient_3 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: :male, registration_user: user, registration_facility: facility)

      create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)
      create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: six_months_ago)
      create(:blood_pressure, patient: patient_2, user: user_2, facility: facility, recorded_at: six_months_ago.advance(days: 3))
      create(:blood_pressure, patient: patient_3, user: user_2, facility: facility, recorded_at: six_months_ago.advance(days: 3))
      refresh_views
      total = described_class.totals(facility)
      expect(total.monthly_follow_ups_htn_or_dm).to eq(3)
      expect(total.monthly_follow_ups_htn_only_male).to eq(1)
      expect(total.monthly_follow_ups_htn_only_female).to eq(2)
    end
  end

  it "returns registrations and follow up counts filtered by diagnosis" do
    two_years_ago, six_months_ago = june_2021.values_at(:two_years_ago, :six_months_ago)
    patient_1 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: "female", registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient_1, user: user_2, facility: facility, recorded_at: six_months_ago.advance(days: 3))
    create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)

    patient_2 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: "male", registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient_2, user: user_2, facility: facility, recorded_at: six_months_ago)

    RefreshReportingViews.call

    two_years_ago_expected = {
      month_date: two_years_ago.to_date,
      monthly_registrations_htn_or_dm: 2,
      monthly_registrations_htn_only: 2,
      monthly_registrations_htn_only_male: 1,
      monthly_registrations_htn_only_female: 1,
      monthly_registrations_htn_only_transgender: 0,
      monthly_registrations_dm_only: 0,
      monthly_registrations_dm_only_male: 0,
      monthly_registrations_dm_only_female: 0,
      monthly_registrations_dm_only_transgender: 0,
      monthly_registrations_htn_and_dm: 0,
      monthly_registrations_htn_and_dm_female: 0,
      monthly_registrations_htn_and_dm_male: 0,
      monthly_registrations_htn_and_dm_transgender: 0,
      monthly_follow_ups_htn_or_dm: 0,
      monthly_follow_ups_htn_only: 0,
      monthly_follow_ups_htn_only_female: 0,
      monthly_follow_ups_htn_only_male: 0,
      monthly_follow_ups_htn_only_transgender: 0,
      monthly_follow_ups_dm_only: 0,
      monthly_follow_ups_dm_only_female: 0,
      monthly_follow_ups_dm_only_male: 0,
      monthly_follow_ups_dm_only_transgender: 0,
      monthly_follow_ups_htn_and_dm: 0,
      monthly_follow_ups_htn_and_dm_female: 0,
      monthly_follow_ups_htn_and_dm_male: 0,
      monthly_follow_ups_htn_and_dm_transgender: 0
    }
    two_years_ago = described_class.find_by(facility: facility, month_date: two_years_ago.to_date)
    region_keys = [:block_region_id, :district_region_id, :facility_id, :facility_region_id, :facility_region_slug, :state_region_id]
    expect(two_years_ago.attributes.symbolize_keys.except(*region_keys)).to eq(two_years_ago_expected)

    six_months_ago_expected = {
      month_date: "Tue, 01 Dec 2020".to_date,
      monthly_registrations_htn_or_dm: 0,
      monthly_registrations_htn_only: 0,
      monthly_registrations_htn_only_male: 0,
      monthly_registrations_htn_only_female: 0,
      monthly_registrations_htn_only_transgender: 0,
      monthly_registrations_dm_only: 0,
      monthly_registrations_dm_only_male: 0,
      monthly_registrations_dm_only_female: 0,
      monthly_registrations_dm_only_transgender: 0,
      monthly_registrations_htn_and_dm: 0,
      monthly_registrations_htn_and_dm_female: 0,
      monthly_registrations_htn_and_dm_male: 0,
      monthly_registrations_htn_and_dm_transgender: 0,
      monthly_follow_ups_htn_or_dm: 2,
      monthly_follow_ups_htn_only: 2,
      monthly_follow_ups_htn_only_female: 1,
      monthly_follow_ups_htn_only_male: 1,
      monthly_follow_ups_htn_only_transgender: 0,
      monthly_follow_ups_dm_only: 0,
      monthly_follow_ups_dm_only_female: 0,
      monthly_follow_ups_dm_only_male: 0,
      monthly_follow_ups_dm_only_transgender: 0,
      monthly_follow_ups_htn_and_dm: 0,
      monthly_follow_ups_htn_and_dm_female: 0,
      monthly_follow_ups_htn_and_dm_male: 0,
      monthly_follow_ups_htn_and_dm_transgender: 0
    }

    six_months_ago = described_class.find_by(facility: facility, month_date: six_months_ago.to_date)
    expect(six_months_ago.attributes.symbolize_keys.except(*region_keys)).to eq(six_months_ago_expected)
  end

  it "monthly totals on progress tab should match the numbers on dashboard" do
    two_years_ago, six_months_ago = june_2021.values_at(:two_years_ago, :six_months_ago)
    patient_1 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: :female, registration_user: user, registration_facility: facility)
    patient_2 = create(:patient, :diabetes, recorded_at: two_years_ago, gender: :female, registration_user: user, registration_facility: facility)
    patient_3 = create(:patient, :hypertension_and_diabetes, recorded_at: two_years_ago, gender: :male, registration_user: user, registration_facility: facility)

    create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient_2, user: user_2, facility: facility, recorded_at: six_months_ago.advance(days: 3))
    create(:blood_pressure, patient: patient_3, user: user_2, facility: facility, recorded_at: six_months_ago.advance(days: 3))
    refresh_views
    total = described_class.totals(facility)
    dashboard_data_six_months_ago = Reports::FacilityState.find_by(facility_id: facility.id, month_date: six_months_ago.to_date.to_s)
    dashboard_data_two_years_ago = Reports::FacilityState.find_by(facility_id: facility.id, month_date: two_years_ago.to_date.to_s)
    dashboard_htn_registrations = dashboard_data_two_years_ago.monthly_registrations
    dashboard_dm_registrations = dashboard_data_two_years_ago.monthly_diabetes_registrations
    dashboard_htn_and_dm_registrations = dashboard_data_two_years_ago.monthly_hypertension_and_diabetes_registrations
    dashboard_htn_follow_ups = dashboard_data_six_months_ago.monthly_follow_ups
    dashboard_dm_follow_ups = dashboard_data_six_months_ago.monthly_diabetes_follow_ups
    expect(total.monthly_registrations_htn_and_dm).to eq(dashboard_htn_and_dm_registrations)
    expect(total.monthly_registrations_htn_or_dm).to eq(dashboard_htn_registrations + dashboard_dm_registrations - dashboard_htn_and_dm_registrations)
    expect(total.monthly_follow_ups_htn_only + total.monthly_follow_ups_htn_and_dm).to eq(dashboard_htn_follow_ups)
    expect(total.monthly_follow_ups_dm_only + total.monthly_follow_ups_htn_and_dm).to eq(dashboard_dm_follow_ups)
  end
end
