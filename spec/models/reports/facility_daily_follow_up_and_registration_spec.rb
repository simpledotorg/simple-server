require "rails_helper"

RSpec.describe Reports::FacilityDailyFollowUpAndRegistration, {type: :model, reporting_spec: true} do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  around do |example|
    with_reporting_time_zone { example.run }
  end

  it "does not contain discarded patients" do
    six_days_ago = 6.days.ago.to_date
    patient = create(:patient, recorded_at: six_days_ago)
    create(:blood_pressure, patient: patient, user: user, facility: facility)
    patient.discard

    described_class.refresh
    result = described_class.find_by(facility_id: facility, visit_date: six_days_ago)

    expect(result.daily_registrations_htn_or_dm).to eq(0)
    expect(result.daily_follow_ups_htn_or_dm).to eq(0)
  end

  it "patients without a medical history are not included" do
    patient = create(:patient, :without_medical_history, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: Date.current)

    described_class.refresh

    result = described_class.find_by(facility_id: facility, visit_date: Date.current)

    expect(result.daily_follow_ups_htn_or_dm).to eq(0)
  end

  it "can be filtered by diagnosis and gender" do
    patient_1 = create(:patient, :hypertension, gender: "transgender", recorded_at: 1.day.ago, registration_user: user, registration_facility: facility)
    mh = build(:medical_history, hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes])
    patient_2 = create(:patient, medical_history: mh, gender: "male", recorded_at: 1.day.ago, registration_user: user, registration_facility: facility)
    patient_3 = create(:patient, :diabetes, gender: "female", recorded_at: 1.day.ago, registration_user: user, registration_facility: facility)
    now = Time.now
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: now)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: now)
    create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: now)
    create(:patient, :diabetes, gender: "male", recorded_at: now, registration_user: user, registration_facility: facility, assigned_facility_id: create(:facility))

    described_class.refresh

    daily_statistics_today = described_class.find_by(facility_id: facility, visit_date: now.to_date)
    daily_statistics_yesterday = described_class.find_by(facility_id: facility, visit_date: 1.day.ago.to_date)

    expect(daily_statistics_today.daily_follow_ups_htn_or_dm).to eq(3)
    expect(daily_statistics_today.daily_follow_ups_htn_only).to eq(1)
    expect(daily_statistics_today.daily_follow_ups_htn_only_transgender).to eq(1)

    expect(daily_statistics_today.daily_follow_ups_dm_only).to eq(1)
    expect(daily_statistics_today.daily_follow_ups_dm_only_female).to eq(1)

    expect(daily_statistics_today.daily_follow_ups_htn_and_dm).to eq(1)
    expect(daily_statistics_today.daily_follow_ups_htn_and_dm_male).to eq(1)

    expect(daily_statistics_today.daily_registrations_htn_or_dm).to eq(1)

    expect(daily_statistics_yesterday.daily_registrations_htn_or_dm).to eq(3)
    expect(daily_statistics_yesterday.daily_registrations_htn_only).to eq(1)
    expect(daily_statistics_yesterday.daily_registrations_htn_only_transgender).to eq(1)

    expect(daily_statistics_yesterday.daily_registrations_dm_only).to eq(1)
    expect(daily_statistics_yesterday.daily_registrations_dm_only_female).to eq(1)

    expect(daily_statistics_yesterday.daily_registrations_htn_and_dm).to eq(1)
    expect(daily_statistics_yesterday.daily_registrations_htn_and_dm_male).to eq(1)
  end

  it "contains records for patient BPs" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: 1.day.ago)

    described_class.refresh

    daily_statistics = described_class.find_by(facility_id: facility, visit_date: 1.day.ago.to_date)

    expect(daily_statistics.daily_follow_ups_htn_or_dm).to eq(1)
  end

  it "contains records for appointments" do
    patient = create(:patient, :hypertension, recorded_at: june_2021[:long_ago])
    now = Time.now
    create(:appointment, patient: patient, facility: facility, device_created_at: now)

    described_class.refresh

    daily_statistics = described_class.find_by(facility_id: facility, visit_date: now.to_date)

    expect(daily_statistics.daily_follow_ups_htn_or_dm).to eq(1)
  end

  it "contains separate records for distinct days" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    with_reporting_time_zone do
      first_day = 1.day.ago
      second_day = 2.days.ago
      create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: first_day)
      create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: second_day)

      described_class.refresh

      follow_ups_on_first_day = described_class.find_by(facility_id: facility, visit_date: first_day.to_date)
      follow_ups_on_second_day = described_class.find_by(facility_id: facility, visit_date: second_day.to_date)
      expect(follow_ups_on_first_day.daily_follow_ups_htn_or_dm).to eq(1)
      expect(follow_ups_on_second_day.daily_follow_ups_htn_or_dm).to eq(1)
    end
  end

  it "contains separate records for distinct facilities" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: 1.day.ago)
    create(:blood_pressure, patient: patient, user: user, facility: another_facility, recorded_at: 1.day.ago)
    create(:patient, :diabetes, gender: "male", recorded_at: 1.day.ago, registration_user: user, registration_facility: facility)

    described_class.refresh

    daily_statistics_facility = described_class.find_by(facility_id: facility, visit_date: 1.day.ago.to_date)
    daily_statistics_another_facility = described_class.find_by(facility_id: facility, visit_date: 1.day.ago.to_date)

    expect(daily_statistics_facility.daily_follow_ups_htn_or_dm).to eq(1)
    expect(daily_statistics_another_facility.daily_follow_ups_htn_or_dm).to eq(1)
    expect(daily_statistics_facility.daily_registrations_htn_or_dm).to eq(1)
  end

  it "does not count more than one visit per day for the same patient and facility" do
    now = Time.current
    facility_2 = create(:facility)
    Timecop.freeze(now) do
      patient = create(:patient, recorded_at: 2.years.ago)

      create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: now)
      create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: now)
      create(:blood_sugar, patient: patient, user: user, facility: facility, recorded_at: now)
      create(:appointment, patient: patient, user: user, facility: facility, recorded_at: now)
      create(:prescription_drug, patient: patient, user: user, facility: facility, recorded_at: now)
      create(:prescription_drug, patient: patient, user: user, facility: facility_2, recorded_at: now)

      described_class.refresh

      daily_statistics_facility = described_class.find_by(facility_id: facility, visit_date: now.to_date)
      daily_statistics_facility_2 = described_class.find_by(facility_id: facility, visit_date: now.to_date)

      expect(daily_statistics_facility.daily_follow_ups_htn_or_dm).to eq(1)
      expect(daily_statistics_facility_2.daily_follow_ups_htn_or_dm).to eq(1)
    end
  end

  it "does not count registration activity as a follow up" do
    now = Time.current
    patient = create(:patient, :hypertension, recorded_at: now, registration_facility: facility)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: now)

    described_class.refresh

    daily_statistics = described_class.find_by(facility_id: facility, visit_date: now.to_date)

    expect(daily_statistics.daily_follow_ups_htn_or_dm).to eq(0)
    expect(daily_statistics.daily_registrations_htn_or_dm).to eq(1)
  end

  it "counts activity the day after registration as a follow up" do
    now = Time.current
    patient = create(:patient, :diabetes, registration_facility: facility, recorded_at: now.advance(days: -1))
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: now)

    described_class.refresh

    daily_statistics_yesterday = described_class.find_by(facility_id: facility, visit_date: 1.day.ago.to_date)
    daily_statistics_today = described_class.find_by(facility_id: facility, visit_date: now.to_date)

    expect(daily_statistics_today.daily_follow_ups_htn_or_dm).to eq(1)
    expect(daily_statistics_yesterday.daily_registrations_htn_or_dm).to eq(1)
  end
end
