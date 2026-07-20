require "rails_helper"

RSpec.describe "Sync traceability", type: :request do
  let(:events) { [] }
  let(:request_user) { create(:user) }
  let(:headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json",
      "HTTP_X_USER_ID" => request_user.id,
      "HTTP_X_FACILITY_ID" => request_user.facility.id,
      "HTTP_AUTHORIZATION" => "Bearer #{request_user.access_token}",
      "HTTP_X_REQUEST_ID" => "request-123",
      "HTTP_IDEMPOTENCY_KEY" => "sync-456"
    }
  end

  around do |example|
    subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args).payload
    end

    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "wraps a successful v3 sync request with authenticated context" do
    get "/api/v3/blood_pressures/sync", headers: headers

    request_events = events.select { |event| event[:boundary] == "request" }
    expect(request_events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(events.first).to equal(request_events.first)
    expect(request_events.first).to include(
      request_id: "request-123",
      idempotency_key: "sync-456",
      operation: "api/v3/blood_pressures#sync_to_user",
      controller: "api/v3/blood_pressures",
      action: "sync_to_user",
      http_method: "GET",
      path: "/api/v3/blood_pressures/sync"
    )
    expect(request_events.first).not_to include(:user_id, :facility_id)
    expect(request_events.last).to include(
      user_id: request_user.id,
      facility_id: request_user.facility.id,
      status: 200,
      outcome: "success"
    )
  end

  it "marks an unauthorized sync request as an error without authenticated context" do
    get "/api/v3/blood_pressures/sync",
      headers: headers.merge("HTTP_AUTHORIZATION" => "Bearer invalid")

    request_finish = events.find do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finish).to include(status: 401, outcome: "error")
    expect(request_finish).not_to include(:user_id, :facility_id)
  end

  it "traces successful pull data boundaries once" do
    get "/api/v3/blood_pressures/sync", headers: headers

    data_events = events.select { |event| event[:boundary] == "data" }
    expect(data_events.group_by { |event| event[:operation] }.transform_values(&:size)).to include(
      "resolve_user" => 2,
      "authenticate_request" => 2,
      "resolve_facility" => 2,
      "select_sync_scope" => 2
    )

    finishes = data_events
      .select { |event| event[:phase] == "finish" }
      .index_by { |event| event[:operation] }
    expect(finishes["authenticate_request"]).to include(
      resource: "users",
      authenticated: true
    )
    expect(finishes["resolve_facility"]).to include(
      resource: "facilities",
      facility_present: true
    )
    expect(finishes["select_sync_scope"]).to include(
      resource: "regions",
      sync_region_id: request_user.facility.facility_group.id
    )
  end

  it "does not trace a non-sync API action" do
    get "/api/v3/ping", headers: {"HTTP_X_REQUEST_ID" => "request-123"}

    expect(response).to have_http_status(:ok)
    expect(events).not_to include(include(boundary: "request"))
  end

  it "wraps a v4 sync action inherited through APIController" do
    get "/api/v4/blood_sugars/sync", headers: headers

    request_events = events.select { |event| event[:boundary] == "request" }
    expect(request_events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(request_events.first).to include(
      operation: "api/v4/blood_sugars#sync_to_user",
      controller: "api/v4/blood_sugars",
      action: "sync_to_user"
    )
    expect(request_events.last).to include(status: 200, outcome: "success")
  end
end
