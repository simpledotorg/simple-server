require "rails_helper"

RSpec.describe Reports::FacilityStateGroup, {type: :model, reporting_spec: true} do
  let(:user) { create(:user) }
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
    expect(result.monthly_registrations_all).to be_nil
    expect(result.monthly_follow_ups_all).to be_nil
  end

  it "patients without a medical history are not included" do
    six_months_ago = june_2021[:six_months_ago]
    patient = create(:patient, :without_medical_history, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: six_months_ago)
    RefreshReportingViews.call
    result = described_class.find_by(facility: facility, month_date: six_months_ago.to_date)
    expect(result.monthly_registrations_all).to be_nil
    expect(result.monthly_follow_ups_all).to be_nil
  end

  it "returns registrations and follow up counts filtered by diagnosis" do
    two_years_ago, six_months_ago = june_2021.values_at(:two_years_ago, :six_months_ago)
    patient_1 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: "female", registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago.advance(days: 3))
    create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: six_months_ago)

    patient_2 = create(:patient, :hypertension, recorded_at: two_years_ago, gender: "male", registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: six_months_ago)

    RefreshReportingViews.call

    two_years_ago_expected = {
      month_date: two_years_ago.to_date,
      monthly_registrations_all: 2,
      monthly_registrations_htn_all: 2,
      monthly_registrations_htn_male: 1,
      monthly_registrations_htn_female: 1,
      monthly_registrations_htn_transgender: 0,
      monthly_registrations_dm_all: 0,
      monthly_registrations_dm_male: 0,
      monthly_registrations_dm_female: 0,
      monthly_registrations_dm_transgender: 0,
      monthly_follow_ups_all: nil,
      monthly_follow_ups_htn_female: nil,
      monthly_follow_ups_htn_male: nil,
      monthly_follow_ups_htn_transgender: nil,
      monthly_follow_ups_dm_all: nil,
      monthly_follow_ups_dm_female: nil,
      monthly_follow_ups_dm_male: nil,
      monthly_follow_ups_dm_transgender: nil
    }
    two_years_ago = described_class.find_by(facility: facility, month_date: two_years_ago.to_date)
    expect(two_years_ago.attributes.symbolize_keys).to include(two_years_ago_expected)

    six_months_ago_expected = {
      month_date: "Tue, 01 Dec 2020".to_date,
      monthly_registrations_all: nil,
      monthly_registrations_htn_all: nil,
      monthly_registrations_htn_male: nil,
      monthly_registrations_htn_female: nil,
      monthly_registrations_htn_transgender: nil,
      monthly_registrations_dm_all: nil,
      monthly_registrations_dm_male: nil,
      monthly_registrations_dm_female: nil,
      monthly_registrations_dm_transgender: nil,
      monthly_follow_ups_all: 2,
      monthly_follow_ups_htn_female: 1,
      monthly_follow_ups_htn_male: 1,
      monthly_follow_ups_htn_transgender: 0,
      monthly_follow_ups_dm_all: 0,
      monthly_follow_ups_dm_female: 0,
      monthly_follow_ups_dm_male: 0,
      monthly_follow_ups_dm_transgender: 0
    }

    six_months_ago = described_class.find_by(facility: facility, month_date: six_months_ago.to_date)
    expect(six_months_ago.attributes.symbolize_keys).to include(six_months_ago_expected)
  end
end
