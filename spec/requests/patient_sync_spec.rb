require 'rails_helper'

RSpec.describe 'Patients sync', type: :request do
  let(:sync_route) { '/api/v1/patients/sync' }
  let(:headers) { { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' } }

  def assert_sync_success(response, processed_since)
    received_patients = JSON(response.body)['patients']

    expect(response.status).to eq 200
    expect(received_patients.count)
      .to eq Patient.updated_on_server_since(processed_since.to_time).count

    # fix phone numbers
    expect(received_patients
             .map { |patient_response| patient_response.with_int_timestamps }
             .to_set)
      .to eq Patient.updated_on_server_since(processed_since.to_time)
               .map { |patient| patient.nested_hash.with_int_timestamps.to_json_and_back }
               .to_set
  end

  it 'pushes nothing, pulls nothing' do
    post sync_route, params: { patients: [] }.to_json, headers: headers
    expect(response.status).to eq 400

    get sync_route, params: { first_time: true }, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body['patients']).to eq([])
    expect(response_body['processed_since']).to eq(Time.new(0).strftime('%FT%T.%3NZ'))
  end

  it 'push a new valid patient and pull first time' do
    valid_patient = build_patient_payload
    post sync_route, params: { patients: [valid_patient] }.to_json, headers: headers
    expect(response.status).to eq 200
    expect(JSON(response.body)['errors']).to eq []

    get sync_route, params: { first_time: true }, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body['patients'].map(&:with_int_timestamps))
      .to eq([valid_patient.with_int_timestamps.to_json_and_back])
    expect(response_body['processed_since'].to_time.to_i).to eq(Patient.first.updated_at.to_i)
  end

  it 'pushes 10 new patients, updates 5, and pulls only updated ones' do
    first_patients_payload = (1..10).map { build_patient_payload }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: { first_time: true }, headers: headers
    processed_since = JSON(response.body)['processed_since']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.take(5).map { |patient| updated_patient_payload patient }
    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { processed_since: processed_since }, headers: headers

    assert_sync_success(response, processed_since)
  end

  it 'pushes 10 new patients, updates only address or phone numbers, and pulls updated ones' do
    first_patients_payload = (1..10).map { build_patient_payload }
    post sync_route, params: { patients: first_patients_payload }.to_json, headers: headers
    get sync_route, params: { first_time: true }, headers: headers
    processed_since = JSON(response.body)['processed_since']

    created_patients         = Patient.find(first_patients_payload.map { |patient| patient['id'] })
    updated_patients_payload = created_patients.map do |patient|
      updated_patient_payload(patient)
        .except(%w(address phone_numbers).sample)
    end

    post sync_route, params: { patients: updated_patients_payload }.to_json, headers: headers
    get sync_route, params: { processed_since: processed_since }, headers: headers

    assert_sync_success(response, processed_since)
  end
end
