require 'rails_helper'

RSpec.shared_examples 'v2 API sync requests' do
  let(:auth_headers) do
    {'HTTP_X_USER_ID' => request_user.id,
     'HTTP_X_FACILITY_ID' => request_user.facility.id,
     'HTTP_AUTHORIZATION' => "Bearer #{request_user.access_token}" }
  end
  let(:headers) do
    { 'ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json' }.merge(auth_headers)
  end

  let(:response_key) { model.to_s.underscore.pluralize }
  let(:empty_payload) { Hash[response_key.to_sym, []] }
  let(:valid_payload) { Hash[response_key.to_sym, [build_payload.call]]}
  let(:created_records) { (1..10).map { build_payload.call } }
  let(:many_valid_records) { Hash[response_key.to_sym, created_records] }
  let(:expected_response) do
    valid_payload[response_key.to_sym].map do |payload|
      response = payload
      if defined? keys_not_expected_in_response.present?
        response = payload.except(*keys_not_expected_in_response)
      end
      response.with_int_timestamps.to_json_and_back
    end
  end
  let(:updated_records) do
    model
      .find(created_records.map { |record| record['id'] })
      .take(5)
      .map(&update_payload)
  end
  let(:updated_payload) { Hash[response_key.to_sym, updated_records] }


  def assert_sync_success(response, request_process_token)
    response_body = JSON(response.body)
    received_records = response_body[response_key]
    request_process_token = parse_process_token({'process_token' => request_process_token })

    expect(response.status).to eq 200
    expect(received_records.count)
      .to eq model.updated_on_server_since(request_process_token[:current_facility_processed_since].to_time).count

    expect(received_records.to_set)
      .to include model.updated_on_server_since(request_process_token[:current_facility_processed_since].to_time)
               .map { |record| to_response(record) }
               .to_set
  end

  it 'pushes nothing, pulls nothing' do
    post sync_route, params: empty_payload.to_json, headers: headers
    expect(response.status).to eq 400

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    response_process_token = parse_process_token(response_body)
    expect(response.status).to eq 200
    expect(response_body[response_key]).to eq([])
    expect(response_process_token[:current_facility_processed_since].to_time).to eq(Time.new(0))
  end

  it 'pushes a new valid record and pull first time' do
    post sync_route, params: valid_payload.to_json, headers: headers
    expect(response.status).to eq 200
    expect(JSON(response.body)['errors']).to eq []

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    response_process_token = parse_process_token(response_body)

    expect(response.status).to eq 200
    expect(response_body[response_key].map(&:with_int_timestamps))
      .to eq(expected_response)
    expect(response_process_token[:current_facility_processed_since].to_time.to_i).to eq(model.first.updated_at.to_i)
  end

  it 'pushes 10 new blood_pressures, updates 5, and pulls only updated ones' do
    post sync_route, params: many_valid_records.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    process_token = JSON(response.body)['process_token']

    post sync_route, params: updated_records.to_json, headers: headers
    get sync_route, params: { process_token: process_token }, headers: headers

    assert_sync_success(response, process_token)
  end
end
