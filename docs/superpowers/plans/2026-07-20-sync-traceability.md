# Sync Traceability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add safe, correlated structured logs and Prometheus metrics at request and data boundaries across API v3/v4 sync.

**Architecture:** Callers wrap explicit boundaries with `Traceability.trace`; the wrapper publishes paired `ActiveSupport::Notifications` events and preserves the wrapped operation's behavior. Focused subscribers convert allowlisted event fields into Ougai logs and bounded-cardinality metrics. A prepended controller concern establishes request context before authentication, while shared sync orchestration and custom sync endpoints add data boundaries.

**Tech Stack:** Ruby 3, Rails 6.1, ActiveSupport::Notifications, RequestStore, Ougai, prometheus_exporter, RSpec, StandardRB

---

## File map

### New files

- `lib/traceability.rb` — safe event schema, request-local context, paired event lifecycle, exception preservation, and subscriber isolation.
- `lib/traceability/log_subscriber.rb` — convert trace events to structured `SIMPLE-REQUEST-LINE` and `SIMPLE-DATA-LINE` logs.
- `lib/traceability/metrics_subscriber.rb` — emit completion counters and histograms with bounded labels.
- `config/initializers/traceability.rb` — require traceability files and register subscribers once.
- `app/controllers/concerns/sync_traceable.rb` — wrap sync HTTP actions and establish correlation context.
- `spec/lib/traceability_spec.rb` — core lifecycle and safety tests.
- `spec/lib/traceability/log_subscriber_spec.rb` — structured logging tests.
- `spec/lib/traceability/metrics_subscriber_spec.rb` — metric tests.
- `spec/requests/api/sync_traceability_spec.rb` — request-level correlation, coverage, failure, and sensitive-data tests.

### Modified files

- `app/controllers/api_controller.rb` — include the request concern and trace authentication, facility resolution, and sync-scope selection only while a sync trace is active.
- `app/controllers/api/v3/sync_controller.rb` — trace push/pull orchestration, batches, audits, transforms, tokens, serialization, and failing record IDs.
- `app/controllers/concerns/api/v3/sync_to_user.rb` — attach trace events to current/other-facility queries while retaining the legacy duration metric.
- `app/controllers/api/v3/facilities_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v3/protocols_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v4/medications_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v4/patient_scores_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v4/questionnaires_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v4/questionnaire_responses_controller.rb` — trace query overrides that bypass the shared concern.
- `app/controllers/api/v4/facility_medical_officers_controller.rb` — trace custom query, transformation, and rendering boundaries.
- `spec/controllers/shared_examples/shared_spec_for_sync_controller.rb` — reusable assertions for shared push/pull boundaries and legacy metrics.
- `spec/controllers/api/v4/facility_medical_officers_controller_spec.rb` — custom endpoint boundary assertions.

## Task 1: Core trace lifecycle and safe schema

**Files:**
- Create: `lib/traceability.rb`
- Create: `spec/lib/traceability_spec.rb`

- [ ] **Step 1: Write failing lifecycle and context tests**

Create `spec/lib/traceability_spec.rb` with examples that subscribe to `Traceability::EVENT_NAME`, capture payloads, and always unsubscribe:

```ruby
require "rails_helper"

RSpec.describe Traceability do
  around do |example|
    subscriber = ActiveSupport::Notifications.subscribe(described_class::EVENT_NAME) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args).payload
    end
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  let(:events) { [] }

  it "publishes paired start and finish events and preserves the result" do
    result = described_class.trace(
      boundary: "data",
      operation: "merge_batch",
      attributes: {resource: "patients", input_count: 2}
    ) do |finish|
      finish[:output_count] = 2
      :result
    end

    expect(result).to eq(:result)
    expect(events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(events.first).to include(
      boundary: "data",
      operation: "merge_batch",
      resource: "patients",
      input_count: 2
    )
    expect(events.last).to include(
      outcome: "success",
      output_count: 2
    )
    expect(events.last[:duration_ms]).to be >= 0
  end

  it "publishes an error finish event and re-raises the same exception" do
    error = RuntimeError.new("secret clinical text")

    expect {
      described_class.trace(boundary: "data", operation: "merge_batch") { raise error }
    }.to raise_error { |raised| expect(raised).to equal(error) }

    expect(events.last).to include(
      phase: "finish",
      outcome: "error",
      error_class: error.class.name
    )
    expect(events.last.values).not_to include(error.message)
  end

  it "merges request context into nested events and restores prior context" do
    described_class.with_context(request_id: "request-1", idempotency_key: "key-1") do
      described_class.add_context(user_id: "user-1")
      described_class.trace(boundary: "data", operation: "query") { :ok }
    end

    expect(events).to all include(
      request_id: "request-1",
      idempotency_key: "key-1",
      user_id: "user-1"
    )
    expect(described_class.active?).to be(false)
  end

  it "drops attributes outside the safe schema" do
    described_class.trace(
      boundary: "data",
      operation: "query",
      attributes: {resource: "patients", patient_name: "private"}
    ) { :ok }

    expect(events).to all include(resource: "patients")
    expect(events).to all satisfy { |event| !event.key?(:patient_name) }
  end

  it "does not alter the operation when notification publication fails" do
    allow(ActiveSupport::Notifications).to receive(:instrument).and_raise("notification failure")

    expect(
      described_class.trace(boundary: "data", operation: "query") { :result }
    ).to eq(:result)
  end
end
```

- [ ] **Step 2: Run the core spec to verify it fails**

Run:

```bash
bin/rspec spec/lib/traceability_spec.rb
```

Expected: FAIL with `NameError: uninitialized constant Traceability`.

- [ ] **Step 3: Implement the core API**

Create `lib/traceability.rb`. Keep the allowlist centralized; both initial and finish attributes pass through it.

```ruby
module Traceability
  EVENT_NAME = "traceability.simple".freeze
  CONTEXT_KEY = :traceability_context

  SAFE_FIELDS = %i[
    phase boundary operation resource request_id idempotency_key
    controller action http_method path user_id facility_id
    outcome duration_ms error_class status
    input_count output_count error_count audit_count record_id
    authenticated facility_present sync_region_id
  ].freeze

  METRIC_LABEL_FIELDS = %i[boundary operation resource outcome].freeze

  module_function

  def trace(boundary:, operation:, attributes: {})
    started_at = monotonic_time
    finish_attributes = sanitize(attributes)
    base_payload = context.merge(finish_attributes).merge(
      boundary: boundary,
      operation: operation
    )

    publish(base_payload.merge(phase: "start"))

    result = yield(finish_attributes)
    finish_attributes[:outcome] ||= "success"
    result
  rescue => error
    finish_attributes ||= {}
    finish_attributes[:outcome] = "error"
    finish_attributes[:error_class] = error.class.name
    raise
  ensure
    if started_at
      finish_payload = context
        .merge(sanitize(finish_attributes || {}))
        .merge(
          boundary: boundary,
          operation: operation,
          phase: "finish",
          duration_ms: ((monotonic_time - started_at) * 1000).round(2)
        )
      publish(finish_payload)
    end
  end

  def with_context(attributes)
    previous_context = RequestStore.store[CONTEXT_KEY]
    RequestStore.store[CONTEXT_KEY] = sanitize(attributes)
    yield
  ensure
    RequestStore.store[CONTEXT_KEY] = previous_context
  end

  def add_context(attributes)
    return unless active?

    RequestStore.store[CONTEXT_KEY] = context.merge(sanitize(attributes))
  end

  def active?
    RequestStore.store[CONTEXT_KEY].present?
  end

  def context
    RequestStore.store[CONTEXT_KEY] || {}
  end

  def sanitize(attributes)
    attributes.to_h.symbolize_keys.slice(*SAFE_FIELDS)
  end

  def publish(payload)
    ActiveSupport::Notifications.instrument(EVENT_NAME, sanitize(payload))
  rescue => error
    begin
      Rails.logger.error(msg: "traceability_publish_error", error_class: error.class.name)
    rescue
      nil
    end
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
```

- [ ] **Step 4: Run the core spec**

Run:

```bash
bin/rspec spec/lib/traceability_spec.rb
```

Expected: 5 examples, 0 failures.

- [ ] **Step 5: Commit the core**

```bash
git add lib/traceability.rb spec/lib/traceability_spec.rb
git commit -m "feat: add traceability event lifecycle"
```

## Task 2: Structured log and metric subscribers

**Files:**
- Create: `lib/traceability/log_subscriber.rb`
- Create: `lib/traceability/metrics_subscriber.rb`
- Create: `config/initializers/traceability.rb`
- Create: `spec/lib/traceability/log_subscriber_spec.rb`
- Create: `spec/lib/traceability/metrics_subscriber_spec.rb`

- [ ] **Step 1: Write failing subscriber tests**

Create `spec/lib/traceability/log_subscriber_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Traceability::LogSubscriber do
  it "logs request events with the request marker" do
    payload = {
      boundary: "request",
      operation: "api/v3/patients#sync_to_user",
      phase: "finish",
      request_id: "request-1",
      status: 200,
      outcome: "success",
      duration_ms: 12.3
    }

    expect(Rails.logger).to receive(:info).with(
      payload.merge(msg: "SIMPLE-REQUEST-LINE")
    )

    described_class.call(payload)
  end

  it "logs data events with the data marker" do
    payload = {
      boundary: "data",
      operation: "merge_batch",
      phase: "start",
      request_id: "request-1",
      resource: "patients"
    }

    expect(Rails.logger).to receive(:info).with(
      payload.merge(msg: "SIMPLE-DATA-LINE")
    )

    described_class.call(payload)
  end
end
```

Create `spec/lib/traceability/metrics_subscriber_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Traceability::MetricsSubscriber do
  let(:payload) do
    {
      boundary: "data",
      operation: "merge_batch",
      resource: "patients",
      outcome: "success",
      phase: "finish",
      duration_ms: 125.0,
      request_id: "must-not-be-a-label",
      user_id: "must-not-be-a-label"
    }
  end

  it "emits completion count and duration with bounded labels" do
    labels = {
      boundary: "data",
      operation: "merge_batch",
      resource: "patients",
      outcome: "success"
    }

    expect(Metrics).to receive(:increment)
      .with("simple_boundary_operations_total", labels)
    expect(Metrics).to receive(:histogram)
      .with("simple_boundary_duration_seconds", 0.125, labels)

    described_class.call(payload)
  end

  it "ignores start events" do
    expect(Metrics).not_to receive(:increment)
    expect(Metrics).not_to receive(:histogram)

    described_class.call(payload.merge(phase: "start"))
  end
end
```

- [ ] **Step 2: Run subscriber specs to verify they fail**

Run:

```bash
bin/rspec spec/lib/traceability/log_subscriber_spec.rb spec/lib/traceability/metrics_subscriber_spec.rb
```

Expected: FAIL because both subscriber constants are undefined.

- [ ] **Step 3: Implement subscribers**

Create `lib/traceability/log_subscriber.rb`:

```ruby
module Traceability
  class LogSubscriber
    def self.call(payload)
      marker = payload[:boundary] == "request" ? "SIMPLE-REQUEST-LINE" : "SIMPLE-DATA-LINE"
      Rails.logger.info(payload.merge(msg: marker))
    end
  end
end
```

Create `lib/traceability/metrics_subscriber.rb`:

```ruby
module Traceability
  class MetricsSubscriber
    def self.call(payload)
      return unless payload[:phase] == "finish"

      labels = payload.slice(*METRIC_LABEL_FIELDS).compact
      Metrics.increment("simple_boundary_operations_total", labels)
      Metrics.histogram(
        "simple_boundary_duration_seconds",
        payload.fetch(:duration_ms) / 1000.0,
        labels
      )
    end
  end
end
```

Create `config/initializers/traceability.rb`:

```ruby
require "traceability"
require "traceability/log_subscriber"
require "traceability/metrics_subscriber"

ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  Traceability::LogSubscriber.call(payload)
  Traceability::MetricsSubscriber.call(payload)
end
```

- [ ] **Step 4: Run subscriber and core specs**

Run:

```bash
bin/rspec spec/lib/traceability_spec.rb spec/lib/traceability/log_subscriber_spec.rb spec/lib/traceability/metrics_subscriber_spec.rb
```

Expected: 9 examples, 0 failures.

- [ ] **Step 5: Commit subscribers**

```bash
git add config/initializers/traceability.rb lib/traceability spec/lib/traceability
git commit -m "feat: emit traceability logs and metrics"
```

## Task 3: Sync request, authentication, and request-context boundaries

**Files:**
- Create: `app/controllers/concerns/sync_traceable.rb`
- Modify: `app/controllers/api_controller.rb`
- Create: `spec/requests/api/sync_traceability_spec.rb`

- [ ] **Step 1: Write failing request-boundary tests**

Create `spec/requests/api/sync_traceability_spec.rb`. Capture notification payloads instead of parsing formatter output:

```ruby
require "rails_helper"

RSpec.describe "Sync traceability", type: :request do
  around do |example|
    subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args).payload
    end
    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

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

  it "wraps a successful sync request and enriches authenticated context" do
    get "/api/v3/patients/sync", headers: headers

    request_events = events.select { |event| event[:boundary] == "request" }
    expect(request_events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(request_events.first).to include(
      request_id: "request-123",
      idempotency_key: "sync-456",
      controller: "api/v3/patients",
      action: "sync_to_user",
      http_method: "GET"
    )
    expect(request_events.last).to include(
      user_id: request_user.id,
      facility_id: request_user.facility.id,
      status: 200,
      outcome: "success"
    )
  end

  it "marks an unauthorized sync request as an error" do
    get "/api/v3/patients/sync", headers: headers.merge("HTTP_AUTHORIZATION" => "Bearer invalid")

    expect(events.last).to include(
      boundary: "request",
      phase: "finish",
      status: 401,
      outcome: "error"
    )
  end
end
```

- [ ] **Step 2: Run request specs to verify they fail**

Run:

```bash
bin/rspec spec/requests/api/sync_traceability_spec.rb
```

Expected: FAIL because no request trace events are emitted.

- [ ] **Step 3: Implement the prepended sync request concern**

Create `app/controllers/concerns/sync_traceable.rb`:

```ruby
module SyncTraceable
  extend ActiveSupport::Concern

  included do
    prepend_around_action :trace_sync_request, if: :sync_trace_action?
  end

  private

  def trace_sync_request
    Traceability.with_context(
      request_id: request.request_id,
      idempotency_key: request.headers["Idempotency-Key"]
    ) do
      Traceability.trace(
        boundary: "request",
        operation: "#{controller_path}##{action_name}",
        attributes: {
          controller: controller_path,
          action: action_name,
          http_method: request.request_method,
          path: request.path
        }
      ) do |finish|
        result = yield
        finish[:status] = response.status
        finish[:outcome] = response.status >= 400 ? "error" : "success"
        result
      end
    end
  end

  def sync_trace_action?
    %w[sync_from_user sync_to_user].include?(action_name)
  end
end
```

- [ ] **Step 4: Add authenticated context and data boundaries in `APIController`**

Include the concern immediately after the class declaration:

```ruby
class APIController < ApplicationController
  include SyncTraceable
```

Replace `current_user`, `validate_facility`, `authenticate`, and `current_sync_region` with traced forms. The helper returns the original block unchanged outside a sync request, so non-sync API behavior and log volume remain unchanged:

```ruby
def trace_sync_data(operation, attributes = {}, &block)
  return yield({}) unless Traceability.active?

  Traceability.trace(
    boundary: "data",
    operation: operation,
    attributes: attributes,
    &block
  )
end

def current_user
  @current_user ||= trace_sync_data("resolve_user", resource: "users") do
    User.find_by(id: request.headers["HTTP_X_USER_ID"])
  end
end

def validate_facility
  trace_sync_data("resolve_facility", resource: "facilities") do |finish|
    facility = current_facility
    finish[:facility_present] = facility.present?
    Traceability.add_context(facility_id: facility.id) if facility.present?
    fail_request(:bad_request, "no current_facility set") unless facility.present?
  end
end

def authenticate
  trace_sync_data("authenticate_request", resource: "users") do |finish|
    authenticated = authenticate_or_request_with_http_token do |token, _options|
      next false unless ActiveSupport::SecurityUtils.secure_compare(token, current_user.access_token)

      RequestStore.store[:current_user] = current_user.to_kv_hash
      Traceability.add_context(user_id: current_user.id)
      current_user.mark_as_logged_in if current_user.has_never_logged_in?
      true
    end
    finish[:authenticated] = authenticated
    authenticated
  end
end

def current_sync_region
  return resolve_current_sync_region unless Traceability.active?

  @traced_current_sync_region ||= trace_sync_data("select_sync_scope", resource: "regions") do |finish|
    region = resolve_current_sync_region
    finish[:sync_region_id] = region.id
    region
  end
end

def resolve_current_sync_region
  return current_facility_group unless current_user
  return current_facility_group if current_user.district_level_sync?
  return current_facility_group if requested_sync_region_id.blank?
  return current_facility_group if requested_sync_region_id == current_facility_group.id
  return current_block if requested_sync_region_id == current_block.id

  current_facility_group
end
```

Keep `trace_sync_data` and `resolve_current_sync_region` private. The extraction preserves the existing branch order.

- [ ] **Step 5: Run request and authentication regression specs**

Run:

```bash
bin/rspec \
  spec/requests/api/sync_traceability_spec.rb \
  spec/requests/api_authentication_spec.rb \
  spec/controllers/api/v3/patients_controller_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Commit request tracing**

```bash
git add app/controllers/concerns/sync_traceable.rb app/controllers/api_controller.rb spec/requests/api/sync_traceability_spec.rb
git commit -m "feat: trace sync request boundaries"
```

## Task 4: Shared push orchestration boundaries

**Files:**
- Modify: `app/controllers/api/v3/sync_controller.rb`
- Modify: `spec/controllers/shared_examples/shared_spec_for_sync_controller.rb`

- [ ] **Step 1: Add failing shared push assertions**

In the `"a working sync controller creating records"` shared example, add:

```ruby
it "traces the push batch with aggregate counts" do
  events = []
  subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
    events << ActiveSupport::Notifications::Event.new(*args).payload
  end

  post(:sync_from_user, params: partially_valid_payload, as: :json)

  finish = events.find do |event|
    event[:operation] == "merge_batch" && event[:phase] == "finish"
  end
  expect(finish).to include(
    resource: request_key,
    input_count: 10,
    output_count: 5,
    error_count: 5,
    audit_count: 5,
    outcome: "success"
  )
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
end

it "adds the failing record id without exposing its attributes" do
  events = []
  subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
    events << ActiveSupport::Notifications::Event.new(*args).payload
  end
  failing = build_payload.call
  allow(controller).to receive(:merge_if_valid).and_raise(ActiveRecord::StatementInvalid, "private payload")

  expect {
    post(:sync_from_user, params: {request_key => [failing]}, as: :json)
  }.to raise_error(ActiveRecord::StatementInvalid)

  finish = events.find do |event|
    event[:operation] == "merge_batch" && event[:phase] == "finish"
  end
  expect(finish).to include(record_id: failing["id"], outcome: "error")
  expect(finish.values).not_to include("private payload")
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
end
```

- [ ] **Step 2: Run one representative controller spec to verify failure**

Run:

```bash
bin/rspec spec/controllers/api/v3/blood_pressures_controller_spec.rb
```

Expected: FAIL because `merge_batch` events do not exist.

- [ ] **Step 3: Instrument push orchestration without reordering merge/audit work**

Replace `__sync_from_user__` and `merge_records` in `app/controllers/api/v3/sync_controller.rb`:

```ruby
def __sync_from_user__(params)
  results = Traceability.trace(
    boundary: "data",
    operation: "merge_batch",
    attributes: {resource: model.table_name, input_count: params.size}
  ) do |finish|
    merged = merge_records(params, finish)
    errors = merged.flat_map { |result| result[:errors_hash] || [] }
    finish[:output_count] = merged.count { |result| result[:record].present? }
    finish[:error_count] = errors.size
    finish[:audit_count] = merged.count { |result| result[:record].present? }
    merged
  end

  errors = Traceability.trace(
    boundary: "data",
    operation: "aggregate_validation_results",
    attributes: {resource: model.table_name}
  ) do |finish|
    aggregated = results.flat_map { |result| result[:errors_hash] || [] }
    finish[:error_count] = aggregated.size
    aggregated
  end

  capture_errors params, errors
  response = {errors: errors.nil? ? nil : errors}

  Traceability.trace(
    boundary: "data",
    operation: "render_push_response",
    attributes: {resource: model.table_name, error_count: errors.size}
  ) { render json: response, status: :ok }
end

def merge_records(params, trace_finish = nil)
  params.flat_map do |single_entity_params|
    begin
      result = merge_if_valid(single_entity_params)
      AuditLog.merge_log(current_user, result[:record]) if result[:record].present?
      result
    rescue
      trace_finish[:record_id] = single_entity_params[:id] if trace_finish
      raise
    end
  end
end
```

This deliberately keeps merge and audit persistence interleaved. `audit_count` provides batch-level coverage without per-record success logs or changing partial-failure side effects.

- [ ] **Step 4: Run representative v3/v4 push specs**

Run:

```bash
bin/rspec \
  spec/controllers/api/v3/blood_pressures_controller_spec.rb \
  spec/controllers/api/v3/patients_controller_spec.rb \
  spec/controllers/api/v4/blood_sugars_controller_spec.rb \
  spec/controllers/api/v4/questionnaire_responses_controller_spec.rb
```

Expected: all examples pass.

- [ ] **Step 5: Commit push tracing**

```bash
git add app/controllers/api/v3/sync_controller.rb spec/controllers/shared_examples/shared_spec_for_sync_controller.rb
git commit -m "feat: trace sync push batches"
```

## Task 5: Shared pull orchestration, tokens, queries, and legacy metric

**Files:**
- Modify: `app/controllers/api/v3/sync_controller.rb`
- Modify: `app/controllers/concerns/api/v3/sync_to_user.rb`
- Modify: `spec/controllers/shared_examples/shared_spec_for_sync_controller.rb`

- [ ] **Step 1: Add failing pull-boundary and legacy-metric tests**

In `"a working V3 sync controller sending records"`, add:

```ruby
it "traces the pull pipeline with aggregate record counts" do
  events = []
  subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
    events << ActiveSupport::Notifications::Event.new(*args).payload
  end

  get :sync_to_user

  finishes = events
    .select { |event| event[:phase] == "finish" }
    .index_by { |event| event[:operation] }

  expect(finishes.keys).to include(
    "retrieve_records",
    "enqueue_audit_logs",
    "transform_records",
    "encode_process_token",
    "render_pull_response"
  )
  expect(finishes["retrieve_records"][:output_count]).to eq(model.count)
  expect(finishes["transform_records"][:output_count]).to eq(model.count)
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
end

it "keeps the existing query duration metric while tracing the query" do
  expect(Metrics).to receive(:benchmark_and_gauge).with(
    "sync_to_user_operation_duration_seconds",
    {
      operation: :current_facility_records,
      model: model.name.downcase
    }
  ).at_least(:once).and_call_original

  get :sync_to_user
end
```

- [ ] **Step 2: Run a representative pull spec to verify failure**

Run:

```bash
bin/rspec spec/controllers/api/v3/blood_pressures_controller_spec.rb
```

Expected: FAIL because pull pipeline events do not exist.

- [ ] **Step 3: Instrument shared pull orchestration**

Replace `__sync_to_user__` in `app/controllers/api/v3/sync_controller.rb`:

```ruby
def __sync_to_user__(response_key)
  records = Traceability.trace(
    boundary: "data",
    operation: "retrieve_records",
    attributes: {resource: model.table_name}
  ) do |finish|
    result = records_to_sync
    finish[:output_count] = result.size
    result
  end

  unless disable_audit_logs?
    Traceability.trace(
      boundary: "data",
      operation: "enqueue_audit_logs",
      attributes: {resource: model.table_name, input_count: records.size}
    ) do |finish|
      AuditLog.create_logs_async(current_user, records, "fetch", Time.current)
      finish[:audit_count] = records.size
    end
  end

  transformed_records = Traceability.trace(
    boundary: "data",
    operation: "transform_records",
    attributes: {resource: model.table_name, input_count: records.size}
  ) do |finish|
    transformed = records.map { |record| transform_to_response(record) }
    finish[:output_count] = transformed.size
    transformed
  end

  encoded_token = Traceability.trace(
    boundary: "data",
    operation: "encode_process_token",
    attributes: {resource: model.table_name}
  ) { encode_process_token(response_process_token) }

  json = Traceability.trace(
    boundary: "data",
    operation: "serialize_pull_response",
    attributes: {resource: model.table_name, input_count: transformed_records.size}
  ) do
    Oj.dump({
      response_key => transformed_records,
      "process_token" => encoded_token
    }, mode: :compat)
  end

  Traceability.trace(
    boundary: "data",
    operation: "render_pull_response",
    attributes: {resource: model.table_name, output_count: transformed_records.size}
  ) { render(json: json, status: :ok) }
end
```

Wrap process-token decoding:

```ruby
def process_token
  @process_token ||= Traceability.trace(
    boundary: "data",
    operation: "decode_process_token",
    attributes: {resource: model.table_name}
  ) do
    if params[:process_token].present?
      JSON.parse(Base64.decode64(params[:process_token])).with_indifferent_access
    else
      {}
    end
  end
end
```

Memoization prevents repeated decode logs and does not change the token during a request.

- [ ] **Step 4: Add tracing around existing timed queries**

Replace `time` in `app/controllers/concerns/api/v3/sync_to_user.rb`:

```ruby
def time(method_name, &block)
  raise ArgumentError, "You must supply a block" unless block

  Traceability.trace(
    boundary: "data",
    operation: method_name.to_s,
    attributes: {resource: model.table_name}
  ) do |finish|
    result = Metrics.benchmark_and_gauge(
      "sync_to_user_operation_duration_seconds",
      {operation: method_name, model: model.name.downcase},
      &block
    )
    finish[:output_count] = result.size if result.respond_to?(:size)
    result
  end
end
```

Also correct the current `yield(block)` implementation to invoke the supplied block through `Metrics.benchmark_and_gauge`; the regression specs must prove the query result is unchanged.

- [ ] **Step 5: Run shared pull and request regression specs**

Run:

```bash
bin/rspec \
  spec/controllers/api/v3/blood_pressures_controller_spec.rb \
  spec/controllers/api/v3/patients_controller_spec.rb \
  spec/controllers/api/v4/patient_scores_controller_spec.rb \
  spec/requests/api/v3/patient_sync_spec.rb \
  spec/requests/api/v4/questionnaire_sync_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Commit shared pull tracing**

```bash
git add app/controllers/api/v3/sync_controller.rb app/controllers/concerns/api/v3/sync_to_user.rb spec/controllers/shared_examples/shared_spec_for_sync_controller.rb
git commit -m "feat: trace sync pull pipeline"
```

## Task 6: Query overrides and custom sync endpoint coverage

**Files:**
- Modify: `app/controllers/api/v3/facilities_controller.rb`
- Modify: `app/controllers/api/v3/protocols_controller.rb`
- Modify: `app/controllers/api/v4/medications_controller.rb`
- Modify: `app/controllers/api/v4/patient_scores_controller.rb`
- Modify: `app/controllers/api/v4/questionnaires_controller.rb`
- Modify: `app/controllers/api/v4/questionnaire_responses_controller.rb`
- Modify: `app/controllers/api/v4/facility_medical_officers_controller.rb`
- Modify: `spec/controllers/api/v4/facility_medical_officers_controller_spec.rb`
- Modify: `spec/requests/api/sync_traceability_spec.rb`

- [ ] **Step 1: Add failing custom endpoint and override tests**

Add to `spec/controllers/api/v4/facility_medical_officers_controller_spec.rb`:

```ruby
it "traces its custom query, transform, and render boundaries" do
  events = []
  subscriber = ActiveSupport::Notifications.subscribe(Traceability::EVENT_NAME) do |*args|
    events << ActiveSupport::Notifications::Event.new(*args).payload
  end

  get :sync_to_user

  operations = events
    .select { |event| event[:phase] == "finish" }
    .map { |event| event[:operation] }
  expect(operations).to include(
    "query_facility_medical_officers",
    "transform_facility_medical_officers",
    "render_pull_response"
  )
ensure
  ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
end
```

Add a v4 override example to `spec/requests/api/sync_traceability_spec.rb`:

```ruby
it "traces overridden patient-score queries" do
  get "/api/v4/patient_scores/sync", headers: headers

  operations = events.map { |event| event[:operation] }
  expect(operations).to include(
    "current_facility_records",
    "other_facility_records",
    "retrieve_records"
  )
end
```

- [ ] **Step 2: Run focused specs to verify failure**

Run:

```bash
bin/rspec \
  spec/controllers/api/v4/facility_medical_officers_controller_spec.rb \
  spec/requests/api/sync_traceability_spec.rb
```

Expected: FAIL because the custom query operations are absent.

- [ ] **Step 3: Wrap query overrides with the shared `time` helper**

For each overridden `current_facility_records` and `other_facility_records` in:

- `app/controllers/api/v3/facilities_controller.rb`
- `app/controllers/api/v3/protocols_controller.rb`
- `app/controllers/api/v4/medications_controller.rb`
- `app/controllers/api/v4/patient_scores_controller.rb`
- `app/controllers/api/v4/questionnaires_controller.rb`
- `app/controllers/api/v4/questionnaire_responses_controller.rb`

wrap the existing body without changing its query. For example, patient scores becomes:

```ruby
def current_facility_records
  time(__method__) do
    @current_facility_records ||=
      PatientScore
        .for_sync
        .where(patient: current_facility.prioritized_patients.select(:id))
        .order(:updated_at, :id)
        .limit(limit)
        .offset((current_page - 1) * limit)
        .to_a
  end
end

def other_facility_records
  time(__method__) { [] }
end
```

Apply the same wrapper to each existing body, including empty-array implementations. Do not alter SQL scopes, memoization, pagination, or return types.

- [ ] **Step 4: Instrument the custom facility-medical-officers endpoint**

Replace `sync_to_user` in `app/controllers/api/v4/facility_medical_officers_controller.rb`:

```ruby
def sync_to_user
  facilities = Traceability.trace(
    boundary: "data",
    operation: "query_facility_medical_officers",
    attributes: {resource: "facility_medical_officers"}
  ) do |finish|
    result = current_facility_group.facilities
      .eager_load(teleconsultation_medical_officers: :phone_number_authentications)
      .to_a
    finish[:output_count] = result.size
    result
  end

  medical_officers = Traceability.trace(
    boundary: "data",
    operation: "transform_facility_medical_officers",
    attributes: {resource: "facility_medical_officers", input_count: facilities.size}
  ) do |finish|
    result = facilities.map { |facility| facility_medical_officers(facility) }
    finish[:output_count] = result.size
    result
  end

  Traceability.trace(
    boundary: "data",
    operation: "render_pull_response",
    attributes: {resource: "facility_medical_officers", output_count: medical_officers.size}
  ) { render json: to_response(medical_officers) }
end
```

- [ ] **Step 5: Run all override and custom endpoint specs**

Run:

```bash
bin/rspec \
  spec/controllers/api/v3/facilities_controller_spec.rb \
  spec/controllers/api/v3/protocols_controller_spec.rb \
  spec/controllers/api/v4/medications_controller_spec.rb \
  spec/controllers/api/v4/patient_scores_controller_spec.rb \
  spec/controllers/api/v4/questionnaires_controller_spec.rb \
  spec/controllers/api/v4/questionnaire_responses_controller_spec.rb \
  spec/controllers/api/v4/facility_medical_officers_controller_spec.rb \
  spec/requests/api/sync_traceability_spec.rb
```

Expected: all examples pass.

- [ ] **Step 6: Commit override coverage**

```bash
git add \
  app/controllers/api/v3/facilities_controller.rb \
  app/controllers/api/v3/protocols_controller.rb \
  app/controllers/api/v4/medications_controller.rb \
  app/controllers/api/v4/patient_scores_controller.rb \
  app/controllers/api/v4/questionnaires_controller.rb \
  app/controllers/api/v4/questionnaire_responses_controller.rb \
  app/controllers/api/v4/facility_medical_officers_controller.rb \
  spec/controllers/api/v4/facility_medical_officers_controller_spec.rb \
  spec/requests/api/sync_traceability_spec.rb
git commit -m "feat: trace custom sync data boundaries"
```

## Task 7: Sensitive-data, failure, and full-suite verification

**Files:**
- Modify: `spec/requests/api/sync_traceability_spec.rb`

- [ ] **Step 1: Add sensitive-data and v4 coverage tests**

Add to `spec/requests/api/sync_traceability_spec.rb`:

```ruby
it "does not publish clinical payloads, tokens, or authorization values" do
  private_name = "PRIVATE PATIENT NAME"
  private_token = "PRIVATE PROCESS TOKEN"
  private_authorization = headers.fetch("HTTP_AUTHORIZATION")
  patient = build(:patient, registration_facility: request_user.facility)
  patient.full_name = private_name
  payload = build_patient_payload(patient)

  post "/api/v3/patients/sync",
    params: {patients: [payload]}.to_json,
    headers: headers.merge("HTTP_X_RESYNC_TOKEN" => private_token)

  serialized_events = events.to_json
  expect(serialized_events).not_to include(private_name)
  expect(serialized_events).not_to include(private_token)
  expect(serialized_events).not_to include(private_authorization)
  expect(events.flat_map(&:keys)).to all satisfy { |key| Traceability::SAFE_FIELDS.include?(key) }
end

it "correlates v4 push and pull boundaries with the same request id" do
  patient = create(:patient, registration_facility: request_user.facility)
  blood_sugar = build_blood_sugar_payload(build(:blood_sugar, patient: patient))
  v4_headers = headers.merge("HTTP_X_REQUEST_ID" => "v4-request")

  post "/api/v4/blood_sugars/sync",
    params: {blood_sugars: [blood_sugar]}.to_json,
    headers: v4_headers

  expect(events).not_to be_empty
  expect(events).to all include(request_id: "v4-request")
  expect(events.map { |event| event[:operation] }).to include(
    "merge_batch",
    "aggregate_validation_results",
    "render_push_response"
  )
end
```

Do not add any sensitive value to the trace allowlist to make the test pass.

- [ ] **Step 2: Run the request traceability spec**

Run:

```bash
bin/rspec spec/requests/api/sync_traceability_spec.rb
```

Expected: all examples pass.

- [ ] **Step 3: Run all traceability and sync specs**

Run:

```bash
bin/rspec \
  spec/lib/traceability_spec.rb \
  spec/lib/traceability \
  spec/requests/api/sync_traceability_spec.rb \
  spec/requests/api/v3 \
  spec/requests/api/v4 \
  spec/controllers/api/v3 \
  spec/controllers/api/v4
```

Expected: 0 failures.

- [ ] **Step 4: Run formatting and focused static checks**

Run:

```bash
bundle exec standardrb \
  lib/traceability.rb \
  lib/traceability \
  config/initializers/traceability.rb \
  app/controllers/concerns/sync_traceable.rb \
  app/controllers/api_controller.rb \
  app/controllers/api/v3/sync_controller.rb \
  app/controllers/concerns/api/v3/sync_to_user.rb \
  app/controllers/api/v3/facilities_controller.rb \
  app/controllers/api/v3/protocols_controller.rb \
  app/controllers/api/v4/medications_controller.rb \
  app/controllers/api/v4/patient_scores_controller.rb \
  app/controllers/api/v4/questionnaires_controller.rb \
  app/controllers/api/v4/questionnaire_responses_controller.rb \
  app/controllers/api/v4/facility_medical_officers_controller.rb \
  spec/lib/traceability_spec.rb \
  spec/lib/traceability \
  spec/requests/api/sync_traceability_spec.rb
```

Expected: no offenses.

- [ ] **Step 5: Verify metric label cardinality and event schema mechanically**

Run:

```bash
rg 'Traceability\.trace|Traceability\.METRIC_LABEL_FIELDS|simple_boundary_' \
  app/controllers lib config/initializers spec
```

Review the output and confirm:

- every `operation` and `resource` value is a string literal or a model table name;
- IDs are absent from `METRIC_LABEL_FIELDS`;
- no request params, process-token values, headers, exception messages, or response bodies are passed as trace attributes;
- every custom `sync_from_user`/`sync_to_user` action has a request boundary through `APIController`.

- [ ] **Step 6: Commit verification tests**

```bash
git add spec/requests/api/sync_traceability_spec.rb
git commit -m "test: verify sync traceability safety"
```

- [ ] **Step 7: Run final branch verification**

Run:

```bash
bin/rspec
bundle exec standardrb
git status --short
```

Expected:

- complete RSpec suite has 0 failures;
- StandardRB reports no offenses;
- only the user's pre-existing untracked files, if still present, appear in `git status --short`.
