require "rails_helper"

RSpec.describe Reporting::PatientVisitsPerMonth, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  describe "the visit definition" do
    it "considers a BP measurement as a visit" do
      bp = create(:blood_pressure, :with_encounter, recorded_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: bp.patient_id, month_date: test_times[:now])
        expect(visit.encounter_facility_id).to eq bp.facility_id
        expect(visit.visited_at).to eq bp.recorded_at
      end
    end

    it "considers a Blood Sugar measurement as a visit" do
      blood_sugar = create(:blood_sugar, :with_encounter, recorded_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: blood_sugar.patient_id, month_date: test_times[:now])
        expect(visit.encounter_facility_id).to eq blood_sugar.facility_id
        expect(visit.visited_at).to eq blood_sugar.recorded_at
      end
    end

    it "considers a Prescription Drug creation as a visit" do
      prescription_drug = create(:prescription_drug, device_created_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: prescription_drug.patient_id, month_date: test_times[:now])
        expect(visit.visited_at).to eq prescription_drug.device_created_at
      end
    end

    it "considers an Appointment creation as a visit" do
      appointment = create(:appointment, device_created_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: appointment.patient_id, month_date: test_times[:now])
        expect(visit.visited_at).to eq appointment.device_created_at
      end
    end

    it "does not consider Teleconsultation as a visit" do
      create(:teleconsultation, device_created_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        expect(described_class.find_by(month_date: test_times[:now]).visited_at).to be_nil
      end
    end

    it "uses the latest visit information for a given month" do
      patient = create(:patient, recorded_at: test_times[:long_ago])
      bp = create(:blood_pressure, :with_encounter, patient: patient, recorded_at: test_times[:over_three_months_ago])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: bp.patient_id, month_date: test_times[:now])
        expect(visit.encounter_facility_id).to eq bp.facility_id
        expect(visit.visited_at).to eq bp.recorded_at
      end

      blood_sugar = create(:blood_sugar, :with_encounter, patient: patient, recorded_at: test_times[:under_three_months_ago])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: blood_sugar.patient_id, month_date: test_times[:now])
        expect(visit.encounter_facility_id).to eq blood_sugar.facility_id
        expect(visit.visited_at).to eq blood_sugar.recorded_at
      end

      prescription_drug = create(:prescription_drug, patient: patient, device_created_at: test_times[:now])
      described_class.refresh
      with_reporting_time_zones do
        visit = described_class.find_by(patient_id: prescription_drug.patient_id, month_date: test_times[:now])
        expect(visit.visited_at).to eq prescription_drug.device_created_at
      end
    end
  end
end
