require "rails_helper"

def create_duplicate_patients
  facility_blue = create(:facility, block: "blue")
  user = create(:user, registration_facility: facility_blue)
  patient_blue = create_regular_patient(registration_time: 6.month.ago, facility: facility_blue, user: user)
  passport_id = patient_blue.business_identifiers.first.identifier

  facility_red = create(:facility, facility_group: facility_blue.facility_group, block: "red")
  patient_red = create_regular_patient(registration_time: 1.month.ago, facility: facility_red, user: user)
  patient_red.business_identifiers.first.update(identifier: passport_id)

  {blue: patient_blue, red: patient_red}
end

def with_comparable_attributes(related_entities)
  related_entities.map do |entity|
    entity.attributes.with_indifferent_access.except(:id, :patient_id, :created_at, :updated_at)
  end
end

describe MergeDuplicatePatients do
  context "#merge" do
    it "creates a new patient with the right associated facilities and users" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)

      new_patient = described_class.new([patient_blue, patient_red]).merge
      expect(new_patient.recorded_at).to eq(patient_blue.recorded_at)
      expect(new_patient.registration_facility).to eq(patient_blue.registration_facility)
      expect(new_patient.registration_user).to eq(patient_blue.registration_user)
      expect(new_patient.assigned_facility).to eq(patient_red.assigned_facility)
      expect(new_patient.device_created_at).to eq(patient_blue.device_created_at)
      expect(new_patient.device_updated_at).to eq(patient_blue.device_updated_at)
    end

    it "Uses the latest available name, gender, address, and reminder consent" do
      patient_earliest = create(:patient, recorded_at: 2.months.ago, full_name: "patient earliest", gender: :male, reminder_consent: "granted")
      patient_not_latest = create(:patient, recorded_at: 2.months.ago, full_name: "patient not latest", gender: :male, reminder_consent: "granted")
      patient_latest = create(:patient, recorded_at: 1.month.ago, full_name: "patient latest", gender: :female, reminder_consent: "denied", address: nil)

      new_patient = described_class.new([patient_earliest, patient_not_latest, patient_latest]).merge

      expect(new_patient.full_name).to eq(patient_latest.full_name)
      expect(new_patient.gender).to eq(patient_latest.gender)
      expect(new_patient.reminder_consent).to eq(patient_latest.reminder_consent)
      expect(new_patient.address.street_address).to eq(patient_not_latest.address.street_address)
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
        expect(new_patient.age_updated_at).to eq(patient_not_latest.age_updated_at)
        expect(new_patient.current_age).to eq(patient_not_latest.current_age)
      end
    end

    it "Uses full set of prescription drugs from latest visit, and ensures history is kept" do
      patient_blue, patient_red = create_duplicate_patients.values_at(:blue, :red)

      new_patient = described_class.new([patient_blue, patient_red]).merge
      expect(new_patient.prescription_drugs.count).to eq(patient_blue.prescription_drugs.count + patient_red.prescription_drugs.count)
      expect(with_comparable_attributes(new_patient.prescribed_drugs)).to match_array(with_comparable_attributes(patient_red.prescribed_drugs))
    end

    it "merges phone numbers uniqued by the number" do
      p1 = create(:patient_phone_number, number: "111111111", dnd_status: true, device_updated_at: 2.months.ago)
      p2 = create(:patient_phone_number, number: "111111111", dnd_status: false, device_updated_at: 1.month.ago)
      p3 = create(:patient_phone_number, number: "3333333333")
      patient_blue = create(:patient, phone_numbers: [p1, p2])
      patient_red = create(:patient, phone_numbers: [p3])

      new_patient = described_class.new([patient_blue, patient_red]).merge

      expect(with_comparable_attributes(new_patient.phone_numbers)).to match_array(with_comparable_attributes([p2, p3]))
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
        device_updated_at: later_medical_history.device_updated_at }.with_indifferent_access.with_int_timestamps)
    end
  end
end
