require "rails_helper"
require "tasks/scripts/move_user_recorded_data_to_registration_facility"

RSpec.describe MoveUserRecordedDataToRegistrationFacility do
  let(:source_facility) { create(:facility) }
  let(:destination_facility) { create(:facility) }
  let(:another_source_facility) { create(:facility) }
  let(:user) { create(:user, registration_facility: destination_facility) }
  let(:service) { MoveUserRecordedDataToRegistrationFacility.new(user, source_facility, destination_facility) }

  describe "#fix_patient_data" do
    let!(:patients_at_correct_facility) { create_list(:patient, 2, registration_user: user, registration_facility: destination_facility) }
    let!(:patients_at_source_facility) { create_list(:patient, 2, registration_user: user, registration_facility: source_facility) }
    let!(:patients_at_another_source_facility) { create_list(:patient, 2, registration_user: user, registration_facility: another_source_facility) }

    it "Moves all patients registered at the wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.to change(Patient.where(registration_user: user, registration_facility: destination_facility), :count).by(2)
    end

    it "Ensures no patients are registered by the user at the wrong facility" do
      expect {
        service.fix_patient_data
      }.to change(Patient.where(registration_user: user, registration_facility: source_facility), :count).to(0)
    end

    it "Does not move patients at a different wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.not_to change(Patient.where(registration_user: user, registration_facility: another_source_facility), :count)
    end

    it "Updates the patients_at_source_facility's updated at timestamp" do
      service.fix_patient_data

      patients_at_source_facility.each do |patient|
        patient.reload
        expect(patient.updated_at).not_to eq(patient.created_at)
      end
    end

    it "Doesn't update the patients_at_correct_facility's updated at timestamp" do
      service.fix_patient_data

      patients_at_correct_facility.each do |patient|
        patient.reload
        expect(patient.updated_at).to eq(patient.created_at)
      end
    end

    it "Updates the patients_at_source_facility's business identifier metadata" do
      service.fix_patient_data
      patients_at_source_facility.each do |patient|
        patient.reload
        expect(patient.business_identifiers.first.metadata).to eq("assigning_user_id" => user.id,
                                                                  "assigning_facility_id" => destination_facility.id)
      end
    end
  end

  describe "#fix_blood_pressures_data" do
    let!(:bps_at_correct_facility) { create_list(:blood_pressure, 2, facility: destination_facility, user: user) }
    let!(:bps_at_source_facility) { create_list(:blood_pressure, 2, user: user, facility: source_facility) }
    let!(:bps_at_another_source_facility) { create_list(:blood_pressure, 2, user: user, facility: another_source_facility) }
    let!(:encounters) do
      [bps_at_correct_facility + bps_at_source_facility + bps_at_another_source_facility].flatten.each do |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility)
      end
    end

    it "Moves all blood pressures recorded at the wrong facility to the user's registration facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(BloodPressure.where(user: user, facility: destination_facility), :count).by 2
    end

    it "Ensures no blood pressures are recorded by the user at the wrong facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(BloodPressure.where(user: user, facility: source_facility), :count).to(0)
    end

    it "Does not move blood pressures at a different wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.not_to change(BloodPressure.where(user: user, facility: another_source_facility), :count)
    end

    it "Updates the bps_at_source_facility's updated at timestamp" do
      service.fix_blood_pressure_data

      bps_at_source_facility.each do |blood_pressure|
        blood_pressure.reload
        expect(blood_pressure.updated_at).not_to eq(blood_pressure.created_at)
      end
    end

    it "Doesn't update the bps_at_correct_facility's updated at timestamp" do
      service.fix_blood_pressure_data

      bps_at_correct_facility.each do |blood_pressure|
        blood_pressure.reload
        expect(blood_pressure.updated_at).to eq(blood_pressure.created_at)
      end
    end

    it "Moves the blood pressures' encounters away from the source facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(Encounter.where(facility: source_facility), :count).to(0)
    end

    it "Moves the blood pressures' encounters to the destination facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(Encounter.where(facility: destination_facility), :count).to(4)
    end

    it "Does not move encounters at a different wrong facility" do
      expect {
        service.fix_blood_pressure_data
      }.not_to(change { Encounter.where(facility: another_source_facility).pluck(:id) })
    end
  end

  describe "#fix_appointments_data" do
    let!(:appointments_at_correct_facility) { create_list(:appointment, 2, facility: destination_facility, user: user) }
    let!(:appointments_at_source_facility) { create_list(:appointment, 2, facility: source_facility, user: user) }
    let!(:appointments_at_another_source_facility) { create_list(:appointment, 2, facility: another_source_facility, user: user) }

    it "Moves all appointments recorded at the wrong facility to the user's registration facility" do
      expect {
        service.fix_appointment_data
      }.to change(Appointment.where(facility: destination_facility), :count).by 2
    end

    it "Ensures no appointments are recorded by the user at the wrong facility" do
      expect {
        service.fix_appointment_data
      }.to change(Appointment.where(facility: source_facility), :count).by(-2)
    end

    it "Does not move appointments at a different wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.not_to change(Appointment.where(facility: another_source_facility), :count)
    end

    it "Updates the appointments_at_source_facility's updated at timestamp" do
      service.fix_appointment_data

      appointments_at_source_facility.each do |appointment|
        appointment.reload
        expect(appointment.updated_at).not_to eq(appointment.created_at)
      end
    end

    it "Doesn't update the appointments_at_correct_facility's updated at timestamp" do
      service.fix_appointment_data

      appointments_at_correct_facility.each do |appointment|
        appointment.reload
        expect(appointment.updated_at).to eq(appointment.created_at)
      end
    end
  end

  describe "#fix_prescription_drugs_data" do
    let!(:prescription_drugs_at_correct_facility) { create_list(:prescription_drug, 2, facility: destination_facility, user: user) }
    let!(:prescription_drugs_at_source_facility) { create_list(:prescription_drug, 2, facility: source_facility, user: user) }
    let!(:prescription_drugs_at_another_source_facility) { create_list(:prescription_drug, 2, facility: another_source_facility, user: user) }

    it "Moves all prescription_drugs recorded at the wrong facility to the user's registration facility" do
      expect {
        service.fix_prescription_drug_data
      }.to change(PrescriptionDrug.where(facility: destination_facility), :count).by 2
    end

    it "Ensures no prescription drugs are recorded by the user at the wrong facility" do
      expect {
        service.fix_prescription_drug_data
      }.to change(PrescriptionDrug.where(facility: source_facility), :count).by(-2)
    end

    it "Does not move prescription drugs at a different wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.not_to change(PrescriptionDrug.where(facility: another_source_facility), :count)
    end

    it "Updates the prescription_drugs_at_source_facility's updated at timestamp" do
      service.fix_prescription_drug_data

      prescription_drugs_at_source_facility.each do |prescription_drug|
        prescription_drug.reload
        expect(prescription_drug.updated_at).not_to eq(prescription_drug.created_at)
      end
    end

    it "Doesn't update the prescription_drugs_at_correct_facility's updated at timestamp" do
      service.fix_prescription_drug_data

      prescription_drugs_at_correct_facility.each do |prescription_drug|
        prescription_drug.reload
        expect(prescription_drug.updated_at).to eq(prescription_drug.created_at)
      end
    end
  end

  describe "#fix_blood_sugars_data" do
    let!(:blood_sugars_at_correct_facility) { create_list(:blood_sugar, 2, facility: destination_facility, user: user) }
    let!(:blood_sugars_at_source_facility) { create_list(:blood_sugar, 2, user: user, facility: source_facility) }
    let!(:blood_sugars_at_another_source_facility) { create_list(:blood_sugar, 2, user: user, facility: another_source_facility) }

    let!(:encounters) do
      [blood_sugars_at_correct_facility + blood_sugars_at_source_facility + blood_sugars_at_another_source_facility].flatten.each do |record|
        create(:encounter, :with_observables, patient: record.patient, observable: record, facility: record.facility)
      end
    end

    it "Moves all blood sugars recorded at the wrong facility to the user's registration facility" do
      expect {
        service.fix_blood_sugar_data
      }.to change(BloodSugar.where(user: user, facility: destination_facility), :count).by 2
    end

    it "Ensures no blood sugars are recorded by the user at the wrong facility" do
      expect {
        service.fix_blood_sugar_data
      }.to change(BloodSugar.where(user: user, facility: source_facility), :count).to(0)
    end

    it "Does not move blood sugars at a different wrong facility to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.not_to change(BloodSugar.where(user: user, facility: another_source_facility), :count)
    end

    it "Updates the blood_sugars_at_source_facility's updated at timestamp" do
      service.fix_blood_sugar_data

      blood_sugars_at_source_facility.each do |blood_sugar|
        blood_sugar.reload
        expect(blood_sugar.updated_at).not_to eq(blood_sugar.created_at)
      end
    end

    it "Doesn't update the blood_sugars_at_correct_facility's updated at timestamp" do
      service.fix_blood_sugar_data

      blood_sugars_at_correct_facility.each do |blood_sugar|
        blood_sugar.reload
        expect(blood_sugar.updated_at).to eq(blood_sugar.created_at)
      end
    end

    it "Moves the blood sugars' encounters away from the source facility" do
      expect {
        service.fix_blood_sugar_data
      }.to change(Encounter.where(facility: source_facility), :count).to(0)
    end

    it "Moves the blood sugars' encounters to the destination facility" do
      expect {
        service.fix_blood_sugar_data
      }.to change(Encounter.where(facility: destination_facility), :count).to(4)
    end

    it "Does not move encounters at a different wrong facility" do
      expect {
        service.fix_blood_sugar_data
      }.not_to(change { Encounter.where(facility: another_source_facility).pluck(:id) })
    end
  end
end
