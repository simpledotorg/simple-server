require 'rails_helper'

RSpec.describe 'Patients sync', type: :request do
  let(:model) { Patient }
  let(:request_user) { FactoryBot.create(:user) }

  let(:sync_route) { '/api/v3/patients/sync' }

  let(:build_payload) { lambda { build_patient_payload(FactoryBot.build(:patient, registration_facility: request_user.registration_facility)) } }
  let(:build_invalid_payload) { lambda { build_invalid_patient_payload } }
  let(:update_payload) { lambda { |record| updated_patient_payload record } }

  def to_response(patient)
    Api::Current::PatientTransformer.to_nested_response(patient)
  end

  include_examples 'current API sync requests'

  it 'pushes 10 new patients, updates only address or phone numbers, and pulls updated ones' do
    first_patients_payload = (1..10).map { build_payload.call }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    process_token = JSON(response.body)['process_token']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.map do |patient|
      updated_patient_payload(patient)
        .except(%w(address phone_numbers business_identifiers).sample)
    end

    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { process_token: process_token }, headers: headers

    assert_sync_success(response, process_token)
  end
end
