require 'rails_helper'

RSpec.describe 'BloodPressures sync', type: :request do
  let(:sync_route) { '/api/v1/blood_pressures/sync' }
  let(:headers) { { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' } }

  def assert_sync_success(response, processed_since)
    received_blood_pressures = JSON(response.body)['blood_pressures']

    expect(response.status).to eq 200
    expect(received_blood_pressures.count)
      .to eq BloodPressure.updated_on_server_since(processed_since.to_time).count

    expect(received_blood_pressures
             .map { |blood_pressure_response| blood_pressure_response }
             .to_set)
      .to eq BloodPressure.updated_on_server_since(processed_since.to_time)
               .map { |blood_pressure| Api::V1::Transformer.to_response(blood_pressure) }
               .to_set
  end

  it 'pushes nothing, pulls nothing' do
    post sync_route, params: { blood_pressures: [] }.to_json, headers: headers
    expect(response.status).to eq 400

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body['blood_pressures']).to eq([])
    expect(response_body['processed_since']).to eq(Time.new(0).strftime('%FT%T.%3NZ'))
  end

  it 'pushes a new valid blood_pressure and pull first time' do
    valid_blood_pressure = build_blood_pressure_payload
    post sync_route, params: { blood_pressures: [valid_blood_pressure] }.to_json, headers: headers
    expect(response.status).to eq 200
    expect(JSON(response.body)['errors']).to eq []

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body['blood_pressures'].map(&:with_int_timestamps))
      .to eq([valid_blood_pressure.with_int_timestamps.to_json_and_back])
    expect(response_body['processed_since'].to_time.to_i).to eq(BloodPressure.first.updated_at.to_i)
  end

  it 'pushes 10 new blood_pressures, updates 5, and pulls only updated ones' do
    first_blood_pressures_payload = (1..10).map { build_blood_pressure_payload }
    post sync_route, params: { blood_pressures: first_blood_pressures_payload }.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    processed_since = JSON(response.body)['processed_since']

    created_blood_pressures         = BloodPressure.find(first_blood_pressures_payload.map { |blood_pressure| blood_pressure['id'] })
    updated_blood_pressures_payload = created_blood_pressures.take(5).map { |blood_pressure| updated_blood_pressure_payload blood_pressure }
    post sync_route, params: { blood_pressures: updated_blood_pressures_payload }.to_json, headers: headers
    get sync_route, params: { processed_since: processed_since }, headers: headers

    assert_sync_success(response, processed_since)
  end
end
