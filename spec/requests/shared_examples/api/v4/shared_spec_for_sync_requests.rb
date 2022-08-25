require "rails_helper"

RSpec.shared_examples "v4 API sync requests" do
  let(:auth_headers) do
    {"HTTP_X_USER_ID" => request_user.id,
     "HTTP_X_FACILITY_ID" => request_user.facility.id,
     "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}"}
  end
  let(:headers) do
    {"ACCEPT" => "application/json", "CONTENT_TYPE" => "application/json"}.merge(auth_headers)
  end

  let(:response_key) { model.to_s.underscore.pluralize }
  let(:empty_payload) { {response_key.to_sym => []} }
  let(:valid_payload) { {response_key.to_sym => [build_payload.call]} }
  let(:created_records) { (1..5).map { build_payload.call } }
  let(:many_valid_records) { {response_key.to_sym => created_records} }
  let(:expected_response) do
    valid_payload[response_key.to_sym].map do |payload|
      response = payload
      response = payload.except(*keys_not_expected_in_response) if defined? keys_not_expected_in_response.present?
      response.with_int_timestamps.to_json_and_back
    end
  end
  let(:updated_records) do
    model
      .find(created_records.map { |record| record["id"] })
      .take(2)
      .map(&update_payload)
  end
  let(:updated_payload) { {response_key.to_sym => updated_records} }

  def assert_sync_success(response, request_process_token)
    response_body = JSON(response.body)
    received_records = response_body[response_key]
    request_process_token = parse_process_token("process_token" => request_process_token)

    expect(response.status).to eq 200
    expect(received_records.count)
      .to eq model.updated_on_server_since(request_process_token[:processed_since].to_time).count

    expect(received_records.to_set)
      .to include model.updated_on_server_since(request_process_token[:processed_since].to_time)
        .map { |record| to_response(record) }
        .to_set
  end

  it "pushes nothing, pulls nothing" do
    post sync_route, params: empty_payload.to_json, headers: headers
    expect(response.status).to eq 400

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    response_process_token = parse_process_token(response_body)
    expect(response.status).to eq 200
    expect(response_body[response_key]).to eq([])
    expect(response_process_token[:processed_since].to_time.to_s).to eq(Time.new(0).to_s)
  end

  it "pushes a new valid record and pull first time" do
    post sync_route, params: valid_payload.to_json, headers: headers
    expect(response.status).to eq 200
    expect(JSON(response.body)["errors"]).to eq []

    get sync_route, params: {}, headers: headers

    response_body = JSON(response.body)
    response_process_token = parse_process_token(response_body)

    expect(response.status).to eq 200
    expect(response_body[response_key].map(&:with_int_timestamps))
      .to match_array(expected_response)
    expect(response_process_token[:processed_since].to_time.to_i).to eq(model.first.updated_at.to_i)
  end

  it "pushes 5 new records, updates 2, and pulls only updated ones" do
    post sync_route, params: many_valid_records.to_json, headers: headers
    get sync_route, params: {}, headers: headers
    process_token = JSON(response.body)["process_token"]

    post sync_route, params: updated_records.to_json, headers: headers
    get sync_route, params: {process_token: process_token}, headers: headers

    assert_sync_success(response, process_token)
  end

  context "resync_token in request headers is present" do
    let(:resync_token) { "1" }
    let(:headers_with_resync_token) { headers.merge("HTTP_X_RESYNC_TOKEN" => resync_token) }
    let(:process_token_without_resync) do
      make_process_token(current_facility_processed_since: Time.current,
        other_facilities_processed_since: Time.current)
    end

    before do
      post sync_route, params: many_valid_records.to_json, headers: headers
    end

    it "syncs all records from beginning if resync_token in process_token is nil" do
      get sync_route, params: {process_token: process_token_without_resync}, headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(5)
      expect(parse_process_token(response_body)[:resync_token]).to eq(resync_token)
    end

    it "syncs all records from beginning if resync_token in headers is different from the one in process_token" do
      get sync_route,
        params: {process_token: make_process_token(current_facility_processed_since: Time.current,
          other_facilities_processed_since: Time.current,
          resync_token: "2")},
        headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(5)
      expect(parse_process_token(response_body)[:resync_token]).to eq(resync_token)
    end

    it "syncs normally once resync_token has been calibrated" do
      get sync_route, params: {process_token: process_token_without_resync}, headers: headers_with_resync_token
      process_token_with_resync = JSON(response.body)["process_token"]

      get sync_route, params: {process_token: process_token_with_resync}, headers: headers_with_resync_token
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(1)
    end

    it "syncs normally if resync_token in headers is the same as the one in process_token" do
      get sync_route, params: {process_token: process_token_without_resync}, headers: headers_with_resync_token
      process_token_with_resync = JSON(response.body)["process_token"]

      get sync_route, params: {process_token: process_token_with_resync}, headers: headers_with_resync_token
      response_body = JSON(response.body)
      expect(response_body[response_key].count).to eq(1)
    end
  end

  context "resync_token in request headers is not present" do
    let(:process_token_without_resync) do
      make_process_token(current_facility_processed_since: 1.year.ago,
        other_facilities_processed_since: 1.year.ago)
    end

    before do
      post sync_route, params: many_valid_records.to_json, headers: headers
    end

    it "syncs normally" do
      get sync_route, params: {process_token: process_token_without_resync}, headers: headers
      response_body = JSON(response.body)

      expect(response_body[response_key].count).to eq(5)
      expect(parse_process_token(response_body)[:resync_token]).to eq(nil)

      get sync_route, params: {process_token: JSON(response.body)["process_token"]}, headers: headers
      expect(JSON(response.body)[response_key].count).to eq(1)
    end
  end
end
