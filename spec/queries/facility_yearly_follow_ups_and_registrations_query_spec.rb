require "rails_helper"

RSpec.describe FacilityYearlyFollowUpsAndRegistrationsQuery do
  it "yearly reports" do
    user = create(:user)
    facility = create(:facility)
    Flipper.enable(:progress_financial_year)
    patient_1 = create(:patient, :hypertension, recorded_at: 2.years.ago, gender: :transgender, registration_user: user, registration_facility: facility)
    patient_2 = create(:patient, :hypertension_and_diabetes, recorded_at: 2.years.ago, gender: :female, registration_user: user, registration_facility: facility)
    patient_3 = create(:patient, :diabetes, recorded_at: 2.years.ago, gender: :male, registration_user: user, registration_facility: facility)

    create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: 6.months.ago)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 5.months.ago)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 6.months.ago)
    create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: 6.months.ago)
    refresh_views
    expected_years = (2017..Date.current.year).to_a.reverse

    yearly_reports = described_class.new(facility, user).call

    expect(yearly_reports.keys).to eq(expected_years)

    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_or_dm"]).to eq(3)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_only"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_only_male"]).to eq(0)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_only_female"]).to eq(0)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_only_transgender"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_only"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_only_male"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_only_female"]).to eq(0)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_only_transgender"]).to eq(0)

    expect(yearly_reports[2.years.ago.year]["yearly_registrations_all"]).to eq(3)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_all"]).to eq(2)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_male"]).to eq(0)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_female"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_transgender"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_all"]).to eq(2)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_male"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_female"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_dm_transgender"]).to eq(0)

    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_and_dm"]).to eq(1)
    expect(yearly_reports[2.years.ago.year]["yearly_registrations_htn_and_dm_transgender"]).to eq(0)

    # 4 Follow-up visits
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_or_dm"]).to eq(4)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_all"]).to eq(4)

    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_only"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_only_male"]).to eq(0)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_only_female"]).to eq(0)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_only_transgender"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_only"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_only_male"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_only_female"]).to eq(0)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_only_transgender"]).to eq(0)

    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_and_dm"]).to eq(2)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_and_dm_female"]).to eq(2)

    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_male"]).to eq(0)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_female"]).to eq(2)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_htn_transgender"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_male"]).to eq(1)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_female"]).to eq(2)
    expect(yearly_reports[6.months.ago.year]["yearly_follow_ups_dm_transgender"]).to eq(0)

    expect(yearly_reports[3.years.ago.year].values).to eq([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.years.ago.year])
  end

  context "progress_financial_year" do
    it "when enabled" do
      user = create(:user)
      facility = create(:facility)
      Flipper.enable(:progress_financial_year)
      patient_1 = create(:patient, :hypertension, recorded_at: 2.years.ago, gender: :transgender, registration_user: user, registration_facility: facility)
      patient_2 = create(:patient, :hypertension_and_diabetes, recorded_at: 2.years.ago, gender: :female, registration_user: user, registration_facility: facility)
      patient_3 = create(:patient, :diabetes, recorded_at: 2.years.ago, gender: :male, registration_user: user, registration_facility: facility)

      create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: 6.months.ago)
      create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 5.months.ago)
      create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 6.months.ago)
      create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: 6.months.ago)
      refresh_views
      expected_years = (2017..Date.current.year).to_a.reverse

      yearly_reports = described_class.new(facility, user).call

      expect(yearly_reports.keys).to eq(expected_years)
    end

    it "when disabled" do
      user = create(:user)
      facility = create(:facility)
      Flipper.disable(:progress_financial_year)
      patient_1 = create(:patient, :hypertension, recorded_at: 2.years.ago, gender: :transgender, registration_user: user, registration_facility: facility)
      patient_2 = create(:patient, :hypertension_and_diabetes, recorded_at: 2.years.ago, gender: :female, registration_user: user, registration_facility: facility)
      patient_3 = create(:patient, :diabetes, recorded_at: 2.years.ago, gender: :male, registration_user: user, registration_facility: facility)

      create(:appointment, patient: patient_1, user: user, facility: facility, recorded_at: 6.months.ago)
      create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 5.months.ago)
      create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 6.months.ago)
      create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: 6.months.ago)
      refresh_views
      expected_years = (2018..Date.current.year).to_a.reverse

      yearly_reports = described_class.new(facility, user).call

      expect(yearly_reports.keys).to eq(expected_years)
    end
  end
end
