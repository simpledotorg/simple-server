# frozen_string_literal: true

require "rails_helper"

def create_duplicate_patients
  facility_blue = create(:facility, name: "Facility Blue")
  user = create(:user, registration_facility: facility_blue)
  patient_blue = create_patient_with_visits(registration_time: 6.month.ago, facility: facility_blue, user: user)
  facility_red = create(:facility, facility_group: facility_blue.facility_group, name: "Facility Red")
  patient_red = create_patient_with_visits(registration_time: 1.month.ago, facility: facility_red, user: user)

  {blue: patient_blue, red: patient_red}
end

def with_comparable_attributes(related_entities)
  related_entities.map do |entity|
    entity.attributes.with_indifferent_access.with_int_timestamps.except(:id, :patient_id, :created_at, :updated_at, :deleted_at)
  end
end

def duplicate_records(deduped_record_ids)
  DeduplicationLog.where(deduped_record_id: Array(deduped_record_ids)).flat_map(&:duplicate_records).uniq
end

describe PatientDeduplication::Deduplicator do
  context "#merge" do
    it "creates a new patient with the right associated facilities and users" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)

      new_patient = described_class.new([patient_blue, patient_red], user: patient_blue.registration_user).merge
      expect(new_patient.recorded_at.to_i).to eq(patient_blue.recorded_at.to_i)
      expect(new_patient.registration_facility).to eq(patient_blue.registration_facility)
      expect(new_patient.registration_user).to eq(patient_blue.registration_user)
      expect(new_patient.assigned_facility).to eq(patient_red.assigned_facility)
      expect(new_patient.device_created_at.to_i).to eq(patient_blue.device_created_at.to_i)
      expect(new_patient.device_updated_at.to_i).to eq(patient_blue.device_updated_at.to_i)
      expect(duplicate_records(new_patient.id)).to match_array([patient_blue, patient_red])
    end

    it "Uses the latest available name, gender, status, address,and reminder consent" do
      patient_earliest = create(:patient, recorded_at: 2.months.ago, full_name: "patient earliest", gender: :male, reminder_consent: "granted")
      patient_not_latest = create(:patient, recorded_at: 2.months.ago, full_name: "patient not latest", gender: :male, reminder_consent: "granted")
      patient_latest = create(:patient, recorded_at: 1.month.ago, full_name: "patient latest", gender: :female, reminder_consent: "denied", address: nil)

      patients = [patient_earliest, patient_not_latest, patient_latest]
      new_patient = described_class.new(patients).merge

      expect(new_patient.full_name).to eq(patient_latest.full_name)
      expect(new_patient.gender).to eq(patient_latest.gender)
      expect(new_patient.status).to eq(patient_latest.status)
      expect(new_patient.reminder_consent).to eq(patient_latest.reminder_consent)
      expect(new_patient.address.street_address).to eq(patient_not_latest.address.street_address)
      expect(duplicate_records(new_patient.address)).to match_array(patients.map(&:address).compact)
    end

    context "age and dob" do
      it "Uses the latest available DoB" do
        patient_earliest = create(:patient, recorded_at: 3.months.ago, age: 42, date_of_birth: Date.parse("1 January 1945"))
        patient_not_latest = create(:patient, recorded_at: 2.month.ago, age: 42, date_of_birth: Date.parse("10 January 1945"))
        patient_latest = create(:patient, recorded_at: 1.month.ago, age: 42, date_of_birth: nil)

        new_patient = described_class.new([patient_earliest, patient_not_latest, patient_latest]).merge

        expect(new_patient.date_of_birth).to eq(patient_not_latest.date_of_birth)
        expect(new_patient.age).to eq(nil)
        expect(new_patient.age_updated_at).to eq(nil)
        expect(new_patient.current_age).to eq(patient_not_latest.current_age)
      end

      it "If there is no DoB, it uses the latest available age" do
        patient_earliest = create(:patient, recorded_at: 3.months.ago, age: 88, date_of_birth: nil, age_updated_at: 2.months.ago)
        patient_not_latest = create(:patient, recorded_at: 2.month.ago, age: 42, date_of_birth: nil, age_updated_at: 1.month.ago)
        patient_latest = create(:patient, recorded_at: 1.month.ago, age: nil, date_of_birth: nil, age_updated_at: 1.month.ago)

        new_patient = described_class.new([patient_earliest, patient_not_latest, patient_latest]).merge

        expect(new_patient.date_of_birth).to eq(nil)
        expect(new_patient.age).to eq(42)
        expect(new_patient.age_updated_at.to_i).to eq(patient_not_latest.age_updated_at.to_i)
        expect(new_patient.current_age).to eq(patient_not_latest.current_age)
      end
    end

    it "Uses full set of prescription drugs from latest visit, and ensures history is kept" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)

      new_patient = described_class.new([patient_blue, patient_red]).merge
      expect(new_patient.prescription_drugs.count).to eq(patient_blue.prescription_drugs.with_discarded.count + patient_red.prescription_drugs.with_discarded.count)
      expect(with_comparable_attributes(new_patient.prescribed_drugs)).to match_array(with_comparable_attributes(patient_red.prescribed_drugs.with_discarded))
      expect(duplicate_records(new_patient.prescription_drugs.map(&:id))).to match_array([patient_blue, patient_red].flat_map { |p| p.prescription_drugs.with_discarded })
    end

    it "merges phone numbers uniqued by the number" do
      patient_blue = create(:patient, phone_numbers: [])
      patient_red = create(:patient, phone_numbers: [])
      _phone_number_1 = create(:patient_phone_number, number: "111111111", dnd_status: true, device_updated_at: 2.months.ago, patient: patient_blue)
      phone_number_2 = create(:patient_phone_number, number: "111111111", dnd_status: false, device_updated_at: 1.month.ago, patient: patient_red)
      phone_number_3 = create(:patient_phone_number, number: "3333333333", patient: patient_red)

      new_patient = described_class.new([patient_blue, patient_red]).merge

      expect(with_comparable_attributes(new_patient.phone_numbers)).to match_array(with_comparable_attributes([phone_number_2, phone_number_3]))
      expect(duplicate_records(new_patient.phone_numbers.map(&:id))).to match_array([phone_number_2, phone_number_3])
    end

    it "merges patient business identifiers uniqued by the identifier" do
      patient_blue = create(:patient, business_identifiers: [])
      patient_red = create(:patient, business_identifiers: [])
      identifier_id = SecureRandom.uuid
      _business_identifier_1 = create(:patient_business_identifier, identifier: identifier_id, device_updated_at: 2.months.ago, patient: patient_blue)
      business_identifier_2 = create(:patient_business_identifier, identifier: identifier_id, device_updated_at: 1.month.ago, patient: patient_red)
      business_identifier_3 = create(:patient_business_identifier, identifier: SecureRandom.uuid, patient: patient_red)

      new_patient = described_class.new([patient_blue, patient_red]).merge

      expect(with_comparable_attributes(new_patient.business_identifiers)).to match_array(with_comparable_attributes([business_identifier_2, business_identifier_3]))
      expect(duplicate_records(new_patient.business_identifiers.map(&:id))).to match_array([business_identifier_2, business_identifier_3])
    end

    it "merges medical histories" do
      earlier_medical_history = create(:medical_history,
        prior_heart_attack_boolean: true,
        prior_stroke_boolean: false,
        chronic_kidney_disease_boolean: nil,
        receiving_treatment_for_hypertension_boolean: nil,
        diabetes_boolean: nil,
        diagnosed_with_hypertension_boolean: nil,
        prior_heart_attack: "yes",
        prior_stroke: "no",
        chronic_kidney_disease: "unknown",
        receiving_treatment_for_hypertension: "no",
        diabetes: "no",
        diagnosed_with_hypertension: "no",
        hypertension: "no",
        device_created_at: 1.month.ago,
        device_updated_at: 1.month.ago,
        created_at: 1.month.ago,
        updated_at: 1.month.ago)

      later_medical_history = create(:medical_history,
        prior_heart_attack_boolean: true,
        prior_stroke_boolean: nil,
        chronic_kidney_disease_boolean: nil,
        receiving_treatment_for_hypertension_boolean: nil,
        diabetes_boolean: false,
        device_created_at: 1.month.ago,
        device_updated_at: 1.month.ago,
        created_at: 1.month.ago,
        updated_at: 1.month.ago,
        diagnosed_with_hypertension_boolean: nil,
        prior_heart_attack: "no",
        prior_stroke: "no",
        chronic_kidney_disease: "no",
        receiving_treatment_for_hypertension: "no",
        diabetes: "yes",
        diagnosed_with_hypertension: "no",
        hypertension: "no")

      new_patient = described_class.new([earlier_medical_history.patient, later_medical_history.patient]).merge
      expect(new_patient.medical_history.attributes.with_indifferent_access.with_int_timestamps).to include({
        prior_heart_attack_boolean: true,
        prior_stroke_boolean: false,
        chronic_kidney_disease_boolean: nil,
        receiving_treatment_for_hypertension_boolean: nil,
        diabetes_boolean: false,
        diagnosed_with_hypertension_boolean: nil,
        prior_heart_attack: "yes",
        prior_stroke: "no",
        chronic_kidney_disease: "no",
        receiving_treatment_for_hypertension: "no",
        diabetes: "yes",
        diagnosed_with_hypertension: "no",
        hypertension: "no",
        user_id: later_medical_history.user.id,
        device_created_at: later_medical_history.device_created_at,
        device_updated_at: later_medical_history.device_updated_at
      }.with_indifferent_access.with_int_timestamps)

      expect(duplicate_records(new_patient.medical_history.id)).to match_array([earlier_medical_history, later_medical_history])
    end

    it "copies over encounters, observations and all observables" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)
      patients = [patient_blue, patient_red]

      visit = create_visit(patient_blue, facility: patient_red.registration_facility, visited_at: patient_red.latest_blood_pressure.recorded_at)

      encounters = Encounter.where(patient_id: patients).load - [visit[:blood_pressure].encounter]
      blood_pressures = BloodPressure.where(patient_id: patients).load
      blood_sugars = BloodSugar.where(patient_id: patients).load
      observables = patients.flat_map(&:observations).map(&:observable)
      soft_deleted_bp = blood_pressures.first
      soft_deleted_sugar = blood_sugars.first
      soft_deleted_bp.discard
      soft_deleted_sugar.discard

      new_patient = described_class.new(patients).merge

      expect(with_comparable_attributes(new_patient.encounters)).to eq with_comparable_attributes(encounters)
      expect(duplicate_records(new_patient.encounters.map(&:id))).to match_array(encounters)

      expect(with_comparable_attributes(new_patient.blood_pressures)).to match_array with_comparable_attributes(blood_pressures - [soft_deleted_bp])
      expect(duplicate_records(new_patient.blood_pressures.map(&:id))).to match_array(blood_pressures - [soft_deleted_bp])

      expect(with_comparable_attributes(new_patient.blood_sugars)).to match_array with_comparable_attributes(blood_sugars - [soft_deleted_sugar])
      expect(duplicate_records(new_patient.blood_sugars.map(&:id))).to match_array(blood_sugars - [soft_deleted_sugar])

      expect(with_comparable_attributes(new_patient.observations.map(&:observable))).to match_array with_comparable_attributes(observables - [soft_deleted_bp, soft_deleted_sugar])
      expect(duplicate_records(new_patient.observations.map(&:observable))).to match_array(observables - [soft_deleted_bp, soft_deleted_sugar])
    end

    it "copies over appointments, keeps only one scheduled appointment and marks the rest as cancelled" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)
      scheduled_appointments = Appointment.where(patient_id: [patient_red, patient_blue]).status_scheduled.order(device_created_at: :desc).load

      new_patient = described_class.new([patient_blue, patient_red]).merge
      patient_blue.appointments.with_discarded.status_scheduled.update_all(status: :cancelled)

      expect(with_comparable_attributes(new_patient.appointments.status_scheduled)).to eq with_comparable_attributes(scheduled_appointments.take(1))
      expected_appointments = Appointment.with_discarded.where(patient_id: [patient_red, patient_blue])
      expect(with_comparable_attributes(new_patient.appointments)).to match_array with_comparable_attributes(expected_appointments)
      expect(duplicate_records(new_patient.appointments.map(&:id))).to match_array(expected_appointments)
    end

    it "copies over teleconsultations" do
      patients = create_duplicate_patients.values
      teleconsultations = Teleconsultation.where(patient_id: patients).load

      new_patient = described_class.new(patients).merge

      expect(with_comparable_attributes(new_patient.teleconsultations)).to match_array with_comparable_attributes(teleconsultations)
      expect(duplicate_records(new_patient.teleconsultations.map(&:id))).to match_array(teleconsultations)
    end

    context "marks patients as merged" do
      it "soft deletes the merged patients" do
        patients = create_duplicate_patients.values

        expect(patients.first).to receive(:discard_data).and_call_original
        expect(patients.last).to receive(:discard_data).and_call_original

        described_class.new(patients).merge

        expect(patients.map(&:discarded?)).to all be true
      end
    end

    context "handles errors" do
      it "less than 2 patients cannot be merged" do
        patients = [create(:patient)]
        instance = described_class.new(patients, user: patients.first.registration_user)
        expect(instance.errors).to eq ["Select at least 2 patients to be merged."]
        expect(instance.merge).to eq nil
      end

      it "catches any error that happens during merge, and adds it to the list of errors" do
        patients = create_duplicate_patients.values
        patients.map(&:medical_history).each(&:discard)

        instance = described_class.new(patients, user: patients.first.registration_user)

        expect(instance.merge).to eq nil
        expect(instance.errors.first[:exception]).to be_present
        expect(instance.errors.first[:patient_ids]).to eq(patients.pluck(:id))
      end
    end
  end
end
