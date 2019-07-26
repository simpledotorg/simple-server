require 'rails_helper'
require 'tasks/data_clean_up/move_user_recorded_data_to_registration_facility'

RSpec.describe MoveUserRecordedDataToRegistrationFacility do
  let(:user_registration_facility) { create(:facility) }
  let(:wrong_facility) { create(:facility) }
  let(:user) { create(:user, registration_facility: user_registration_facility) }
  let(:service) { MoveUserRecordedDataToRegistrationFacility.new(user, wrong_facility) }

  describe "#fix_patient_data" do
    let!(:patients_at_correct_facility) { create_list(:patient, 2, registration_user: user, registration_facility: user_registration_facility) }
    let!(:patients_at_wrong_facility) { create_list(:patient, 2, registration_user: user, registration_facility: wrong_facility) }

    it "Moves all patients registered to the user's registration facility" do
      expect {
        service.fix_patient_data
      }.to change(Patient.where(registration_user: user, registration_facility: user_registration_facility), :count).by(2)
    end

    it "ensures no patients are registered by the user at the wrong facility" do
      expect {
        service.fix_patient_data
      }.to change(Patient.where(registration_user: user, registration_facility: wrong_facility), :count).to(0)
    end


    it "Updates the patients_at_wrong_facility's updated at timestamp" do
      service.fix_patient_data

      patients_at_wrong_facility.each do |patient|
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
  end

  describe "#fix_blood_pressures_data" do
    let!(:bps_at_correct_facility) { create_list(:blood_pressure, 2, facility: user_registration_facility, user: user) }
    let!(:bps_at_wrong_facility) { create_list(:blood_pressure, 2, user: user, facility: wrong_facility) }

    it "Moves all blood pressures recorded to the user's registration facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(BloodPressure.where(user: user, facility: user_registration_facility), :count).by (2)
    end

    it "ensures no blood pressures are recorded by the user at the wrong facility" do
      expect {
        service.fix_blood_pressure_data
      }.to change(BloodPressure.where(user: user, facility: wrong_facility), :count).to(0)
    end


    it "Updates the bps_at_wrong_facility's updated at timestamp" do
      service.fix_blood_pressure_data

      bps_at_wrong_facility.each do |blood_pressure|
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
  end

  describe "#fix_appointments_data" do
    let!(:appointments_at_correct_facility) { create_list(:appointment, 2, facility: user_registration_facility) }
    let!(:appointments_at_wrong_facility) { create_list(:appointment, 2, facility: wrong_facility) }

    before :each do
      (appointments_at_correct_facility + appointments_at_wrong_facility).each do |appointment|
        create(:audit_log, action: 'create', auditable: appointment, user: user)
      end
    end

    it "Moves all appointments recorded to the user's registration facility" do
      expect {
        service.fix_appointment_data
      }.to change(Appointment.where(facility: user_registration_facility), :count).by (2)
    end

    it "ensures no appointments are recorded by the user at the wrong facility" do
      expect {
        service.fix_appointment_data
      }.to change(Appointment.where(facility: wrong_facility), :count).by(-2)
    end

    it "Updates the appointments_at_wrong_facility's updated at timestamp" do
      service.fix_appointment_data

      appointments_at_wrong_facility.each do |appointment|
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
    let!(:prescription_drugs_at_correct_facility) { create_list(:prescription_drug, 2, facility: user_registration_facility) }
    let!(:prescription_drugs_at_wrong_facility) { create_list(:prescription_drug, 2, facility: wrong_facility) }

    before :each do
      (prescription_drugs_at_correct_facility + prescription_drugs_at_wrong_facility).each do |prescription_drug|
        create(:audit_log, action: 'create', auditable: prescription_drug, user: user)
      end
    end

    it "Moves all prescription_drugs recorded to the user's registration facility" do
      expect {
        service.fix_prescription_drug_data
      }.to change(PrescriptionDrug.where(facility: user_registration_facility), :count).by (2)
    end

    it "ensures no blood pressures are recorded by the user at the wrong facility" do
      expect {
        service.fix_prescription_drug_data
      }.to change(PrescriptionDrug.where(facility: wrong_facility), :count).by(-2)
    end

    it "Updates the prescription_drugs_at_wrong_facility's updated at timestamp" do
      service.fix_prescription_drug_data

      prescription_drugs_at_wrong_facility.each do |prescription_drug|
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
end
