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

    expect(response).to have_http_status(:unauthorized)
    expect(response.body).to eq("HTTP Token: Access denied.\n")

    request_finish = events.find do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finish).to include(status: 401, outcome: "error")
    expect(request_finish).not_to include(:user_id, :facility_id)

    authentication_finish = events.find do |event|
      event[:boundary] == "data" &&
        event[:operation] == "authenticate_request" &&
        event[:phase] == "finish"
    end
    expect(authentication_finish).to include(authenticated: false, outcome: "error")
  end

  it "does not add an unauthorized facility to request context" do
    unauthorized_facility = create(:facility, facility_group: create(:facility_group))

    get "/api/v3/blood_pressures/sync",
      headers: headers.merge("HTTP_X_FACILITY_ID" => unauthorized_facility.id)

    expect(response).to have_http_status(:unauthorized)

    request_finish = events.find do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finish).to include(
      user_id: request_user.id,
      status: 401,
      outcome: "error"
    )
    expect(request_finish).not_to include(:facility_id)
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

  it "traces custom query overrides reached by their sync endpoints" do
    endpoints = {
      "/api/v3/facilities/sync" => ["other_facility_records"],
      "/api/v3/protocols/sync" => ["other_facility_records"],
      "/api/v4/medications/sync" => ["other_facility_records"],
      "/api/v4/questionnaires/sync?dsl_version=1" =>
        %w[current_facility_records other_facility_records],
      "/api/v4/questionnaire_responses/sync" =>
        %w[current_facility_records other_facility_records]
    }

    endpoints.each do |path, expected_operations|
      events.clear
      get path, headers: headers

      expect(response).to have_http_status(:ok)
      query_events = events.select do |event|
        event[:boundary] == "data" &&
          expected_operations.include?(event[:operation])
      end
      expect(query_events.map { |event| [event[:operation], event[:phase]] }).to eq(
        expected_operations.flat_map { |operation| [[operation, "start"], [operation, "finish"]] }
      )
      query_finishes = query_events.select { |event| event[:phase] == "finish" }
      expect(query_finishes).to all(include(outcome: "success"))
      expect(query_finishes).to all(satisfy { |event| event[:output_count].is_a?(Integer) })
    end
  end

  it "executes the questionnaire SELECT inside its single trace without a COUNT query" do
    create(:questionnaire, :active, questionnaire_type: stub_questionnaire_types.first, dsl_version: "1")
    sequence = []
    trace_subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args).payload
      if event[:operation] == "current_facility_records"
        sequence << :"trace_#{event[:phase]}"
      end
    end
    sql_subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      sql = ActiveSupport::Notifications::Event.new(*args).payload[:sql]
      next unless sql.include?('FROM "questionnaires"')

      sequence << (sql.match?(/\bCOUNT\b/i) ? :count : :select)
    end

    get "/api/v4/questionnaires/sync?dsl_version=1", headers: headers

    expect(response).to have_http_status(:ok)
    expect(sequence).to eq(%i[trace_start select trace_finish])
  ensure
    ActiveSupport::Notifications.unsubscribe(trace_subscriber) if trace_subscriber
    ActiveSupport::Notifications.unsubscribe(sql_subscriber) if sql_subscriber
  end

  it "wraps the custom facility medical officers batches in one request boundary" do
    get "/api/v4/facility_medical_officers/sync", headers: headers

    request_events = events.select { |event| event[:boundary] == "request" }
    expect(request_events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(request_events.first).to include(
      operation: "api/v4/facility_medical_officers#sync_to_user"
    )
    expect(request_events.last).to include(status: 200, outcome: "success")

    operations = %w[
      query_facility_medical_officers
      transform_facility_medical_officers
      render_pull_response
    ]
    custom_events = events.select do |event|
      event[:boundary] == "data" && operations.include?(event[:operation])
    end
    expect(custom_events.map { |event| [event[:operation], event[:phase]] }).to eq(
      operations.flat_map { |operation| [[operation, "start"], [operation, "finish"]] }
    )
    expect(custom_events.select { |event| event[:phase] == "finish" })
      .to all(include(resource: "facility_medical_officers", outcome: "success"))
  end

  it "includes the status when ParameterMissing is rescued as a bad request" do
    post "/api/v3/patients/sync", params: {}, headers: headers

    expect(response).to have_http_status(:bad_request)

    request_finishes = events.select do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finishes.one?).to be(true)
    expect(request_finishes.first).to include(
      status: 400,
      outcome: "error",
      error_class: "ActionController::ParameterMissing"
    )
  end

  it "includes the status when RecordNotFound is rescued as not found" do
    allow_any_instance_of(Api::V3::BloodPressuresController)
      .to receive(:sync_to_user)
      .and_raise(ActiveRecord::RecordNotFound)

    get "/api/v3/blood_pressures/sync", headers: headers

    expect(response).to have_http_status(:not_found)

    request_finishes = events.select do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finishes.one?).to be(true)
    expect(request_finishes.first).to include(
      status: 404,
      outcome: "error",
      error_class: "ActiveRecord::RecordNotFound"
    )
  end

  it "maps an unhandled exception to 500 and re-raises the same exception" do
    error = RuntimeError.new("unexpected")
    allow_any_instance_of(Api::V3::BloodPressuresController)
      .to receive(:sync_to_user)
      .and_raise(error)

    expect {
      get "/api/v3/blood_pressures/sync", headers: headers
    }.to raise_error { |raised_error| expect(raised_error).to equal(error) }

    request_finishes = events.select do |event|
      event[:boundary] == "request" && event[:phase] == "finish"
    end
    expect(request_finishes.one?).to be(true)
    expect(request_finishes.first).to include(
      status: 500,
      outcome: "error",
      error_class: "RuntimeError"
    )
  end
end
