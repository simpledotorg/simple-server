require "rails_helper"

RSpec.describe LatestBloodPressuresPerPatientPerDay, type: :model do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
  end

  describe "assigned facility" do
    let!(:facility) { create(:facility) }
    let!(:patient) { create(:patient, assigned_facility: facility) }
    let!(:blood_pressure) { create(:blood_pressure, patient: patient) }
    before { described_class.refresh }

    it "stores the assigned facility" do
      expect(described_class.find_by_bp_id(blood_pressure.id).assigned_facility_id).to eq facility.id
    end
  end

  describe "patient status and medical history fields" do
    it "stores and updates patient status" do
      patient_1 = create(:patient, status: :migrated)
      patient_2 = create(:patient, status: :dead)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)

      LatestBloodPressuresPerPatientPerDay.refresh

      bp_per_day_1 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_1.id)
      expect(bp_per_day_1.patient_status).to eq("migrated")
      bp_per_day_2 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_2.id)
      expect(bp_per_day_2.patient_status).to eq("dead")

      patient_1.update!(status: :active)

      LatestBloodPressuresPerPatientPerDay.refresh

      bp_per_day_1 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_1.id)
      expect(bp_per_day_1.patient_status).to eq("active")
    end

    it "stores and updates medical_history_hypertension" do
      patient_1 = create(:patient)
      patient_2 = create(:patient, :without_hypertension)
      patient_3 = create(:patient, :without_medical_history)

      create(:blood_pressure, patient: patient_1)
      create(:blood_pressure, patient: patient_2)
      create(:blood_pressure, patient: patient_3)

      LatestBloodPressuresPerPatientPerDay.refresh

      bp_per_day_1 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_1.id)
      expect(bp_per_day_1.medical_history_hypertension).to eq("yes")
      bp_per_day_2 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_2.id)
      expect(bp_per_day_2.medical_history_hypertension).to eq("no")
      bp_per_day_3 = LatestBloodPressuresPerPatientPerDay.find_by!(patient_id: patient_3.id)
      expect(bp_per_day_3.medical_history_hypertension).to be_nil
    end
  end
end
