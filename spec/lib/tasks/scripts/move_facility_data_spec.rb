require "rails_helper"
require "tasks/scripts/move_facility_data"

RSpec.describe MoveFacilityData do
  let(:source_facility) { create(:facility) }
  let(:destination_facility) { create(:facility) }
  let(:another_source_facility) { create(:facility) }
  let(:user) { create(:user, registration_facility: destination_facility) }

  describe "#fix_patient_data" do
    it "Moves all patients registered at the source facility to the destination facility" do
      patient_1 = create(:patient, registration_user: user, registration_facility: source_facility)
      patient_2 = create(:patient, registration_user: user, registration_facility: source_facility, assigned_facility: create(:facility))

      described_class.new(source_facility, destination_facility, user: user).fix_patient_data

      expect(Patient.where(id: [patient_1, patient_2]).pluck(:registration_facility_id)).to all eq(destination_facility.id)
      expect(patient_1.reload.assigned_facility_id).to eq(destination_facility.id)
      expect(patient_2.reload.assigned_facility_id).not_to eq(destination_facility.id)
    end

    it "Does not move patients from a different facility" do
      create_list(:patient, 2, registration_user: user, registration_facility: another_source_facility)

      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_patient_data
      }.not_to change(Patient.where(registration_user: user, registration_facility: another_source_facility), :count)
    end

    it "Updates the patients at source facility's updated at timestamp" do
      patients_at_source_facility = create_list(:patient, 2, registration_user: user, registration_facility: source_facility)
      described_class.new(source_facility, destination_facility, user: user).fix_patient_data

      patients_at_source_facility.each do |patient|
        patient.reload
        expect(patient.updated_at).not_to eq(patient.created_at)
      end
    end

    it "Doesn't update the patients at destination facility's updated at timestamp" do
      patients_at_destination_facility = create_list(:patient, 2, registration_user: user, registration_facility: destination_facility)
      described_class.new(source_facility, destination_facility, user: user).fix_patient_data

      patients_at_destination_facility.each do |patient|
        patient.reload
        expect(patient.updated_at).to eq(patient.created_at)
      end
    end

    it "Updates the patients at source facility's business identifier metadata" do
      patients_at_source_facility = create_list(:patient, 2, registration_user: user, registration_facility: source_facility)

      described_class.new(source_facility, destination_facility, user: user).fix_patient_data
      patients_at_source_facility.each do |patient|
        patient.reload
        expect(patient.business_identifiers.first.metadata).to eq("assigning_user_id" => user.id,
          "assigning_facility_id" => destination_facility.id)
      end
    end
  end

  describe "#fix_blood_pressures_data" do
    it "Moves all blood pressures recorded at the source facility to the destination facility" do
      create_list(:blood_pressure, 2, user: user, facility: source_facility)

      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_blood_pressure_data
      }.to change(BloodPressure.where(user: user, facility: destination_facility), :count).by 2
    end

    it "Updates the bps_at_source_facility's updated at timestamp" do
      bps_at_source_facility = create_list(:blood_pressure, 2, user: user, facility: source_facility)
      described_class.new(source_facility, destination_facility, user: user).fix_blood_pressure_data

      bps_at_source_facility.each do |blood_pressure|
        blood_pressure.reload
        expect(blood_pressure.updated_at).not_to eq(blood_pressure.created_at)
      end
    end

    it "Doesn't update the bps_at_destination_facility's updated at timestamp" do
      bps_at_destination_facility = create_list(:blood_pressure, 2, facility: destination_facility, user: user)
      described_class.new(source_facility, destination_facility, user: user).fix_blood_pressure_data

      bps_at_destination_facility.each do |blood_pressure|
        blood_pressure.reload
        expect(blood_pressure.updated_at).to eq(blood_pressure.created_at)
      end
    end

    it "Moves the blood pressures' encounters away from the source facility" do
      create_list(:blood_pressure, 2, :with_encounter, user: user, facility: source_facility)

      described_class.new(source_facility, destination_facility, user: user).fix_blood_pressure_data

      expect(Encounter.where(facility: source_facility).count).to eq(0)
      expect(Encounter.where(facility: destination_facility).count).to eq(2)
    end

    it "Does not move encounters from a different source facility" do
      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data
      }.not_to(change { Encounter.where(facility: another_source_facility).pluck(:id) })
    end
  end

  describe "#fix_appointments_data" do
    it "Moves all appointments recorded at the source facility to the destination facility" do
      create_list(:appointment, 2, facility: source_facility, user: user)

      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_appointment_data
      }.to change(Appointment.where(facility: destination_facility), :count).by 2
    end

    it "Updates the appointments_at_source_facility's updated at timestamp" do
      appointments_at_source_facility = create_list(:appointment, 2, facility: source_facility, user: user)
      described_class.new(source_facility, destination_facility, user: user).fix_appointment_data

      appointments_at_source_facility.each do |appointment|
        appointment.reload
        expect(appointment.updated_at).not_to eq(appointment.created_at)
      end
    end

    it "Doesn't update the appointments_at_destination_facility's updated at timestamp" do
      appointments_at_destination_facility = create_list(:appointment, 2, facility: destination_facility, user: user)

      described_class.new(source_facility, destination_facility, user: user).fix_appointment_data

      appointments_at_destination_facility.each do |appointment|
        appointment.reload
        expect(appointment.updated_at).to eq(appointment.created_at)
      end
    end
  end

  describe "#fix_prescription_drugs_data" do
    it "Moves all prescription_drugs recorded at the source facility to the destination facility" do
      create_list(:prescription_drug, 2, facility: source_facility, user: user)
      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_prescription_drug_data
      }.to change(PrescriptionDrug.where(facility: destination_facility), :count).by 2
    end

    it "Updates the prescription_drugs_at_source_facility's updated at timestamp" do
      prescription_drugs_at_source_facility = create_list(:prescription_drug, 2, facility: source_facility, user: user)
      described_class.new(source_facility, destination_facility, user: user).fix_prescription_drug_data

      prescription_drugs_at_source_facility.each do |prescription_drug|
        prescription_drug.reload
        expect(prescription_drug.updated_at).not_to eq(prescription_drug.created_at)
      end
    end

    it "Doesn't update the prescription_drugs_at_destination_facility's updated at timestamp" do
      prescription_drugs_at_destination_facility = create_list(:prescription_drug, 2, facility: destination_facility, user: user)
      described_class.new(source_facility, destination_facility, user: user).fix_prescription_drug_data

      prescription_drugs_at_destination_facility.each do |prescription_drug|
        prescription_drug.reload
        expect(prescription_drug.updated_at).to eq(prescription_drug.created_at)
      end
    end
  end

  describe "#fix_teleconsultations_data" do
    it "Moves all teleconsultations recorded at the source facility to the destination facility" do
      create_list(:teleconsultation, 2, facility: source_facility, requester: user)
      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_teleconsultation_data
      }.to change(Teleconsultation.where(facility: destination_facility), :count).by 2
    end

    it "Updates the teleconsultations_at_source_facility's updated at timestamp" do
      teleconsultations_at_source_facility = create_list(:teleconsultation, 2, facility: source_facility, requester: user)
      described_class.new(source_facility, destination_facility, user: user).fix_teleconsultation_data

      teleconsultations_at_source_facility.each do |teleconsultation|
        teleconsultation.reload
        expect(teleconsultation.updated_at).not_to eq(teleconsultation.created_at)
      end
    end

    it "Doesn't update the teleconsultations_at_destination_facility's updated at timestamp" do
      teleconsultations_at_destination_facility = create_list(:teleconsultation, 2, facility: destination_facility, requester: user)
      described_class.new(source_facility, destination_facility, user: user).fix_teleconsultation_data

      teleconsultations_at_destination_facility.each do |teleconsultation|
        teleconsultation.reload
        expect(teleconsultation.updated_at).to eq(teleconsultation.created_at)
      end
    end
  end

  describe "#fix_blood_sugars_data" do
    it "Moves all blood sugars recorded at the source facility to the destination facility" do
      create_list(:blood_sugar, 2, user: user, facility: source_facility)
      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data
      }.to change(BloodSugar.where(user: user, facility: destination_facility), :count).by 2
    end

    it "Updates the blood_sugars_at_source_facility's updated at timestamp" do
      blood_sugars_at_source_facility = create_list(:blood_sugar, 2, user: user, facility: source_facility)
      described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data

      blood_sugars_at_source_facility.each do |blood_sugar|
        blood_sugar.reload
        expect(blood_sugar.updated_at).not_to eq(blood_sugar.created_at)
      end
    end

    it "Doesn't update the blood_sugars_at_destination_facility's updated at timestamp" do
      blood_sugars_at_destination_facility = create_list(:blood_sugar, 2, facility: destination_facility, user: user)
      described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data

      blood_sugars_at_destination_facility.each do |blood_sugar|
        blood_sugar.reload
        expect(blood_sugar.updated_at).to eq(blood_sugar.created_at)
      end
    end

    it "Moves the blood sugar's encounters away from the source facility" do
      create_list(:blood_sugar, 2, :with_encounter, user: user, facility: source_facility)

      described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data

      expect(Encounter.where(facility: source_facility).count).to eq(0)
      expect(Encounter.where(facility: destination_facility).count).to eq(2)
    end

    it "Does not move encounters from a different source facility" do
      expect {
        described_class.new(source_facility, destination_facility, user: user).fix_blood_sugar_data
      }.not_to(change { Encounter.where(facility: another_source_facility).pluck(:id) })
    end
  end

  describe "#move_data" do
    context "when user is not supplied" do
      it "moves all data from source facility to destination facility" do
        create_list(:patient, 2, registration_facility: source_facility)
        create_list(:blood_pressure, 2, facility: source_facility)
        create_list(:blood_sugar, 2, facility: source_facility)
        create_list(:appointment, 2, facility: source_facility)
        create_list(:prescription_drug, 2, facility: source_facility)
        create_list(:teleconsultation, 2, facility: source_facility)

        described_class.new(source_facility, destination_facility).move_data

        expect(Patient.where(registration_facility: destination_facility).count).to eq(2)
        expect(BloodPressure.where(facility: destination_facility).count).to eq(2)
        expect(Appointment.where(facility: destination_facility).count).to eq(2)
        expect(BloodSugar.where(facility: destination_facility).count).to eq(2)
        expect(PrescriptionDrug.where(facility: destination_facility).count).to eq(2)
        expect(Teleconsultation.where(facility: destination_facility).count).to eq(2)
      end
    end
  end
end
