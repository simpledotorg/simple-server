require 'rails_helper'

RSpec.shared_examples 'sync requests' do
  def assert_sync_success(response, processed_since)
    received_records = JSON(response.body)[response_key]

    expect(response.status).to eq 200
    expect(received_records.count)
      .to eq model.updated_on_server_since(processed_since.to_time).count

    expect(received_records.to_set)
      .to eq model.updated_on_server_since(processed_since.to_time)
               .map { |record| to_response(record) }
               .to_set
  end

  it 'pushes nothing, pulls nothing' do
    post sync_route, params: empty_payload.to_json, headers: headers
    expect(response.status).to eq 400

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body[response_key]).to eq([])
    expect(response_body['processed_since']).to eq(Time.new(0).strftime('%FT%T.%3NZ'))
  end

  it 'pushes a new valid record and pull first time' do
    post sync_route, params: valid_payload.to_json, headers: headers
    expect(response.status).to eq 200
    expect(JSON(response.body)['errors']).to eq []

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    expect(response.status).to eq 200
    expect(response_body[response_key].map(&:with_int_timestamps))
      .to eq(expected_response)
    expect(response_body['processed_since'].to_time.to_i).to eq(model.first.updated_at.to_i)
  end

  it 'pushes 10 new blood_pressures, updates 5, and pulls only updated ones' do
    post sync_route, params: many_valid_records.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    processed_since = JSON(response.body)['processed_since']

    post sync_route, params: updated_records.to_json, headers: headers
    get sync_route, params: { processed_since: processed_since }, headers: headers

    assert_sync_success(response, processed_since)
  end
end