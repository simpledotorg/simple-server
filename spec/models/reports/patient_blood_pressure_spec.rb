require "rails_helper"

describe Reports::PatientBloodPressure, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  around do |example|
    with_reporting_time_zone { example.run }
  end

  it "has the latest blood sugar details for every month a patient has their blood sugar measured" do
    patient = create(:patient)
    blood_pressure_1 = create(:blood_pressure, patient: patient, recorded_at: 6.months.ago)
    blood_pressure_2 = create(:blood_pressure, patient: patient, recorded_at: 2.months.ago)
    blood_pressure_3 = create(:blood_pressure, patient: patient, recorded_at: 1.months.ago)
    blood_pressure_4 = create(:blood_pressure, patient: patient)

    refresh_views
    results = Reports::PatientBloodPressure.all.pluck(
      :month_date,
      :blood_pressure_id,
      :patient_id
    )
    expect(results).to include(
      [june_2021[:six_months_ago].to_date, blood_pressure_1.id, patient.id],
      [june_2021[:two_months_ago].to_date, blood_pressure_2.id, patient.id],
      [june_2021[:one_month_ago].to_date, blood_pressure_3.id, patient.id],
      [june_2021[:now].to_date, blood_pressure_4.id, patient.id]
    )
  end

  context "screening" do
    it "doesn't include blood pressures of screened patients" do
      patient = create(:patient, diagnosed_confirmed_at: nil)
      create(:medical_history, patient: patient, hypertension: "suspected", diabetes: "no")

      refresh_views
      results = Reports::PatientBloodPressure.where(patient_id: patient.id)
      expect(results).to be_empty
    end

    it "calculates the registration indicators based on the diagnosis date" do
      patient = create(:patient, recorded_at: Date.new(2024, 5, 1), diagnosed_confirmed_at: Date.new(2024, 6, 1))
      create(:blood_pressure, patient: patient, recorded_at: Date.new(2024, 5, 1))
      create(:blood_pressure, patient: patient, recorded_at: Date.new(2024, 6, 1))
      refresh_views
      june_record = described_class.find_by(patient_id: patient.id, month_date: Date.new(2024, 6, 1))
      july_record = described_class.find_by(patient_id: patient.id, month_date: Date.new(2024, 7, 1))
      august_record = described_class.find_by(patient_id: patient.id, month_date: Date.new(2024, 8, 1))
      expect(june_record.patient_registered_at).to eq(patient.diagnosed_confirmed_at)
      expect(june_record.months_since_registration).to eq(0)
      expect(july_record.months_since_registration).to eq(1)
      expect(august_record.months_since_registration).to eq(2)
      expect(june_record.quarters_since_registration).to eq(0)
      expect(july_record.quarters_since_registration).to eq(1)
      expect(august_record.quarters_since_registration).to eq(1)
    end
  end
end
