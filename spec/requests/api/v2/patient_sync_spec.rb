require 'rails_helper'

RSpec.describe 'Patients sync', type: :request do
  let(:model) { Patient }
  let(:request_user) { FactoryBot.create(:user) }

  let(:sync_route) { '/api/v2/patients/sync' }
  let(:blood_pressure_sync_route) { '/api/v2/blood_pressures/sync' }

  let(:build_payload) { lambda { build_patient_payload_v2(FactoryBot.build(:patient, registration_facility: request_user.facility)) } }
  let(:build_invalid_payload) { lambda { build_invalid_patient_payload } }
  let(:update_payload) { lambda { |record| updated_patient_payload record } }

  let(:keys_not_expected_in_response) {['business_identifiers']}

  def to_response(patient)
    Api::V2::PatientTransformer.to_nested_response(patient)
  end

  include_examples 'v2 API sync requests'

  it 'pushes 10 new patients, updates only address or phone numbers, and pulls updated ones' do
    first_patients_payload = (1..10).map { build_payload.call }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    process_token = JSON(response.body)['process_token']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.map do |patient|
      updated_patient_payload(patient)
        .except(%w(address phone_numbers).sample)
    end

    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { process_token: process_token }, headers: headers

    assert_sync_success(response, process_token)
  end

  it "sets recorded_at to the earliest bp's recorded_at in case patient is synced later" do
    patient = FactoryBot.build(:patient)

    blood_pressure_recorded_at = 1.month.ago
    blood_pressure = FactoryBot.build(:blood_pressure,
                                      patient: patient,
                                      device_created_at: blood_pressure_recorded_at)
    blood_pressure_payload = build_blood_pressure_payload_v2(blood_pressure)
    post blood_pressure_sync_route, params: { blood_pressures: [blood_pressure_payload] }.to_json, headers: headers

    patient_payload = build_patient_payload_v2(patient)
    post sync_route, params: { patients: [patient_payload] }.to_json, headers: headers

    patient_in_db = Patient.find(patient.id)
    expect(patient_in_db.recorded_at).to eq(blood_pressure_recorded_at)
  end
end
