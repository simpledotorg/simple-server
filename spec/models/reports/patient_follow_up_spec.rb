require "rails_helper"

RSpec.describe Reports::PatientFollowUp, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should belong_to(:user) }
  end

  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  it "does not contain discarded patients" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    patient.discard

    RefreshReportingViews.call

    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up).to be_nil
  end

  it "patients without a medical history are not included" do
    patient = create(:patient, :without_medical_history, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    RefreshReportingViews.call
    expect(described_class.count).to eq(0)
  end

  it "can be filtered by diagnosis" do
    patient_1 = create(:patient, :hypertension, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    mh = build(:medical_history, hypertension: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes], diabetes: MedicalHistory::MEDICAL_HISTORY_ANSWERS[:yes])
    patient_2 = create(:patient, medical_history: mh, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    patient_3 = create(:patient, :diabetes, recorded_at: june_2021[:long_ago], registration_user: user, registration_facility: facility)
    create(:blood_pressure, patient: patient_1, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient_2, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient_3, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call
    follow_ups = described_class.where(facility: facility)
    expect(follow_ups.count).to eq(3)
    expect(follow_ups.with_hypertension.count).to eq(2)
    expect(follow_ups.with_diabetes.count).to eq(2)
    follow_ups.each do |follow_up|
      expect(follow_up.month_date).to eq(june_2021[:now].to_date)
    end
  end

  it "contains records for patient BPs" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end

  it "contains records for appointments" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end

  it "contains records for appointments" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end

  it "contains separate records for distinct months" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:over_3_months_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:under_3_months_ago])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, user: user, facility: facility)
    expect(follow_ups.map(&:month_string).sort).to eq(["2021-03", "2021-04"])
  end

  it "contains separate records for distinct users in the same month" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_user = create(:user)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient, user: another_user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, month_string: june_2021[:month_string], facility: facility)
    expect(follow_ups.map(&:user)).to contain_exactly(user, another_user)
  end

  it "contains separate records for distinct facilities" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_facility = create(:facility)

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: patient, user: user, facility: another_facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(patient: patient, month_string: june_2021[:month_string], user: user)
    expect(follow_ups.map(&:facility)).to contain_exactly(facility, another_facility)
  end

  it "contains separate records for distinct patients" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    another_patient = create(:patient, recorded_at: june_2021[:long_ago])

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:now])
    create(:blood_pressure, patient: another_patient, user: user, facility: facility, recorded_at: june_2021[:now])

    RefreshReportingViews.call

    expect(described_class.count).to eq(2)
    follow_ups = described_class.where(month_string: june_2021[:month_string], facility: facility, user: user)
    expect(follow_ups.map(&:patient)).to contain_exactly(patient, another_patient)
  end

  it "does not count activity in the registration month" do
    patient = create(:patient, recorded_at: june_2021[:beginning_of_month])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])

    RefreshReportingViews.call

    expect(described_class.count).to eq(0)
  end

  it "does not count more than one visit per month for the same patient, facility, and user" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])

    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:beginning_of_month])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:blood_sugar, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:appointment, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])
    create(:prescription_drug, patient: patient, user: user, facility: facility, recorded_at: june_2021[:end_of_month])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility, month_string: june_2021[:month_string])
    expect(follow_up).to be_present
  end

  it "identifies months in the reporting timezone" do
    patient = create(:patient, recorded_at: june_2021[:over_12_months_ago])
    create(:blood_pressure, patient: patient, user: user, facility: facility, recorded_at: june_2021[:under_12_months_ago])

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
  end

  context "screening" do
    it "doesn't include screened patients" do
      screened_patient = create(:patient, :without_medical_history, diagnosed_confirmed_at: nil)
      described_class.refresh
      expect(described_class.where(patient_id: screened_patient.id).count).to eq(0)
    end

    it "includes blood pressure after date of diagnosis" do
      diagnosed_patient = create(:patient, :hypertension, recorded_at: june_2021[:three_months_ago], diagnosed_confirmed_at: june_2021[:two_months_ago], registration_user: user, registration_facility: facility)
      _old_bp = create(:blood_pressure, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:three_months_ago])
      new_bp = create(:blood_pressure, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:now])
      described_class.refresh
      expect(described_class.where(patient: diagnosed_patient).pluck(:visit_id)).to eq([new_bp.id])
    end

    it "includes blood sugars after date of diagnosis" do
      diagnosed_patient = create(:patient, :hypertension, recorded_at: june_2021[:three_months_ago], diagnosed_confirmed_at: june_2021[:two_months_ago], registration_user: user, registration_facility: facility)
      _old_bs = create(:blood_sugar, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:three_months_ago])
      new_bs = create(:blood_sugar, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:now])
      described_class.refresh
      expect(described_class.where(patient: diagnosed_patient).pluck(:visit_id)).to eq([new_bs.id])
    end

    it "includes appointments after date of diagnosis" do
      diagnosed_patient = create(:patient, :hypertension, recorded_at: june_2021[:three_months_ago], diagnosed_confirmed_at: june_2021[:two_months_ago], registration_user: user, registration_facility: facility)
      _old_appointment = create(:appointment, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:three_months_ago])
      new_appointment = create(:appointment, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:now])
      described_class.refresh
      expect(described_class.where(patient: diagnosed_patient).pluck(:visit_id)).to eq([new_appointment.id])
    end

    it "includes prescriptions after date of diagnosis" do
      diagnosed_patient = create(:patient, :hypertension, recorded_at: june_2021[:three_months_ago], diagnosed_confirmed_at: june_2021[:two_months_ago], registration_user: user, registration_facility: facility)
      _old_prescription = create(:appointment, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:three_months_ago])
      new_prescription = create(:appointment, patient: diagnosed_patient, user: user, facility: facility, recorded_at: june_2021[:now])
      described_class.refresh
      expect(described_class.where(patient: diagnosed_patient).pluck(:visit_id)).to eq([new_prescription.id])
    end
  end
end
