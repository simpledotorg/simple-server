# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::PatientVisit, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
  end

  around do |example|
    Timecop.freeze("June 30 2021 5:30 UTC") do # June 30th 23:00 IST time
      example.run
    end
  end

  it "does not include deleted visit data" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    bp = create(:bp_with_encounter, patient: patient, recorded_at: june_2021[:over_3_months_ago], deleted_at: june_2021[:now])
    bp.encounter.update(deleted_at: june_2021[:now])
    blood_sugar = create(:blood_sugar_with_encounter, patient: patient, recorded_at: june_2021[:over_3_months_ago], deleted_at: june_2021[:now])
    blood_sugar.encounter.update(deleted_at: june_2021[:now])
    _prescription_drug = create(:prescription_drug, patient: patient, recorded_at: june_2021[:over_3_months_ago], deleted_at: june_2021[:now])
    _appointment = create(:appointment, patient: patient, recorded_at: june_2021[:over_3_months_ago], deleted_at: june_2021[:now])

    described_class.refresh
    with_reporting_time_zone do
      expect(described_class.find_by(patient_id: patient.id, month_date: june_2021[:now]).visited_at).to be_nil
    end
  end

  describe "visited_facility_ids" do
    it "aggregates all the facilities visited in a given month, but uses only latest encounter" do
      patient = create(:patient, recorded_at: june_2021[:now])
      bp = create(:bp_with_encounter, patient: patient, recorded_at: june_2021[:now] + 1.minute)
      blood_sugar = create(:blood_sugar_with_encounter, patient: patient, recorded_at: june_2021[:now])
      prescription_drug = create(:prescription_drug, patient: patient, recorded_at: june_2021[:now])
      appointment = create(:appointment, patient: patient, recorded_at: june_2021[:now])

      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: patient.id, month_date: june_2021[:now])
        expect(visit.visited_facility_ids).to match_array [bp.facility_id, prescription_drug.facility_id, appointment.creation_facility_id]
        expect(visit.visited_facility_ids).not_to include(blood_sugar.facility_id)
      end
    end
  end

  describe "the visit definition" do
    it "considers a BP measurement as a visit" do
      bp = create(:blood_pressure, :with_encounter, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: bp.patient_id, month_date: june_2021[:now])
        expect(visit.encounter_facility_id).to eq bp.facility_id
        expect(visit.visited_at).to eq bp.recorded_at
      end
    end

    it "considers a Blood Sugar measurement as a visit" do
      blood_sugar = create(:blood_sugar, :with_encounter, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: blood_sugar.patient_id, month_date: june_2021[:now])
        expect(visit.encounter_facility_id).to eq blood_sugar.facility_id
        expect(visit.visited_at).to eq blood_sugar.recorded_at
      end
    end

    it "considers a Prescription Drug creation as a visit" do
      prescription_drug = create(:prescription_drug, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: prescription_drug.patient_id, month_date: june_2021[:now])
        expect(visit.visited_at).to eq prescription_drug.recorded_at
      end
    end

    it "considers an Appointment creation as a visit" do
      appointment = create(:appointment, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: appointment.patient_id, month_date: june_2021[:now])
        expect(visit.visited_at).to eq appointment.recorded_at
      end
    end

    it "does not consider Teleconsultation as a visit" do
      create(:teleconsultation, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        expect(described_class.find_by(month_date: june_2021[:now]).visited_at).to be_nil
      end
    end

    it "uses the latest visit information for a given month" do
      patient = create(:patient, recorded_at: june_2021[:long_ago])
      bp = create(:blood_pressure, :with_encounter, patient: patient, recorded_at: june_2021[:over_3_months_ago])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: bp.patient_id, month_date: june_2021[:now])
        expect(visit.encounter_facility_id).to eq bp.facility_id
        expect(visit.visited_at).to eq bp.recorded_at
      end

      blood_sugar = create(:blood_sugar, :with_encounter, patient: patient, recorded_at: june_2021[:under_3_months_ago])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: blood_sugar.patient_id, month_date: june_2021[:now])
        expect(visit.encounter_facility_id).to eq blood_sugar.facility_id
        expect(visit.visited_at).to eq blood_sugar.recorded_at
      end

      prescription_drug = create(:prescription_drug, patient: patient, recorded_at: june_2021[:now])
      described_class.refresh
      with_reporting_time_zone do
        visit = described_class.find_by(patient_id: prescription_drug.patient_id, month_date: june_2021[:now])
        expect(visit.visited_at).to eq prescription_drug.recorded_at
      end
    end
  end
end
