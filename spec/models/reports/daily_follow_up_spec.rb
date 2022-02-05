require "rails_helper"

RSpec.describe Reports::DailyFollowUp, {type: :model, reporting_spec: true} do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  around do |example|
    with_reporting_time_zone { example.run }
  end

  it "does not contain discarded patients" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility)
    patient.discard

    described_class.refresh

    expect(described_class.count).to eq(0)
  end

  it "does not contain records from more than 30 days ago" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: 31.days.ago)

    described_class.refresh

    expect(described_class.count).to eq(0)
  end

  it "patients without a medical history are not included" do
    patient = create(:patient, :without_medical_history, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    described_class.refresh

    expect(described_class.count).to eq(0)
  end

  it "can be filtered by diagnosis" do
    patient_1 = create(:patient, :hypertension, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    mh = build(:medical_history, hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes])
    patient_2 = create(:patient, medical_history: mh, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    patient_3 = create(:patient, :diabetes, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: 3.days.ago)
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: 2.days.ago)
    create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: 1.day.ago)

    described_class.refresh

    follow_ups = described_class.where(facility: facility)
    expect(follow_ups.count).to eq(3)
    expect(follow_ups.with_hypertension.count).to eq(2)
    expect(follow_ups.with_diabetes.count).to eq(2)
  end

  it "contains records for patient BPs" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: 1.day.ago)

    described_class.refresh

    expect(described_class.count).to eq(1)
  end

  it "contains records for appointments" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:appointment, patient: patient, facility: facility)

    described_class.refresh

    expect(described_class.count).to eq(1)
  end

  it "contains records for appointments" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:appointment, patient: patient, facility: facility)

    described_class.refresh

    expect(described_class.count).to eq(1)
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

      expect(described_class.count).to eq(2)
      follow_ups = described_class.where(patient: patient, facility: facility)
      expect(follow_ups.map(&:day_of_year)).to contain_exactly(first_day.yday, second_day.yday)
    end
  end

  it "contains separate records for distinct facilities" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: 1.day.ago)
    create(:blood_pressure, patient: patient, user: user, facility: another_facility, recorded_at: 1.day.ago)

    described_class.refresh

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient)
    expect(follow_ups.map(&:facility)).to contain_exactly(facility, another_facility)
  end

  it "does not count more than one visit per day for the same patient and facility" do
    pending
    patient = create(:patient, recorded_at: june_2021[:long_ago])

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:beginning_of_month])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:blood_sugar, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:prescription_drug, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])

    described_class.refresh

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility, month_string: june_2021[:month_string])
    expect(follow_up).to be_present
  end
end
