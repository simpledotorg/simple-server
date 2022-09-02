require "rails_helper"
require Rails.root.join("db", "data", "20220902131201_back_fill_patient_id_facility_id_call_result")

RSpec.describe BackFillPatientIdFacilityIdCallResult do
  it "fills the patient ID and facility ID for all call results" do
    call_result = create(:call_result, patient_id: nil, facility_id: nil)
    appointment = call_result.appointment
    patient = appointment.patient
    facility = appointment.facility

    described_class.new.up
    call_result.reload

    expect(call_result.patient_id).to eq patient.id
    expect(call_result.facility_id).to eq facility.id
  end

  it "will override any existing data in call results" do
    other_patient = create(:patient)
    other_facility = create(:facility)
    call_result = create(:call_result, patient: other_patient, facility: other_facility)
    appointment = call_result.appointment
    patient = appointment.patient
    facility = appointment.facility

    described_class.new.up
    call_result.reload

    expect(call_result.patient_id).to eq patient.id
    expect(call_result.facility_id).to eq facility.id
  end
end
