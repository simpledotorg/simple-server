require "rails_helper"

RSpec.describe Traceability do
  let(:events) { [] }

  around do |example|
    subscriber = ActiveSupport::Notifications.subscribe(described_class::EVENT_NAME) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args).payload
    end

    example.run
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  it "defines the exact event and context contracts" do
    expect(described_class::EVENT_NAME).to eq("traceability.simple")
    expect(described_class::CONTEXT_KEY).to eq(:traceability_context)
    expect(described_class::SAFE_FIELDS).to match_array(
      %i[
        phase boundary operation resource request_id idempotency_key
        controller action http_method path user_id facility_id
        outcome duration_ms error_class status
        input_count output_count error_count audit_count record_id
        authenticated facility_present sync_region_id
      ]
    )
    expect(described_class::METRIC_LABEL_FIELDS).to match_array(
      %i[boundary operation resource outcome]
    )
  end

  it "publishes paired start and finish events" do
    described_class.trace(
      boundary: "data",
      operation: "merge_batch",
      attributes: {resource: "patients", input_count: 2}
    ) { :ok }

    expect(events.map { |event| event[:phase] }).to eq(%w[start finish])
    expect(events.first).to include(
      boundary: "data",
      operation: "merge_batch",
      resource: "patients",
      input_count: 2
    )
    expect(events.last).to include(
      boundary: "data",
      operation: "merge_batch",
      resource: "patients",
      input_count: 2,
      outcome: "success"
    )
  end

  it "preserves the wrapped return value" do
    result = described_class.trace(boundary: "data", operation: "query") { :result }

    expect(result).to eq(:result)
  end

  it "adds safe finish attributes by mutating the yielded hash" do
    described_class.trace(boundary: "data", operation: "merge_batch") do |finish_attributes|
      finish_attributes[:output_count] = 2
      finish_attributes[:patient_name] = "private"
    end

    expect(events.first).not_to have_key(:output_count)
    expect(events.last).to include(output_count: 2)
    expect(events.last).not_to have_key(:patient_name)
  end

  it "records a monotonic nonnegative duration in milliseconds" do
    allow(described_class).to receive(:monotonic_time).and_return(10.0, 10.125)

    described_class.trace(boundary: "data", operation: "query") { :ok }

    expect(events.last[:duration_ms]).to eq(125.0)
    expect(events.last[:duration_ms]).to be >= 0
  end

  it "publishes a safe error finish event and re-raises the same exception" do
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

  it "enriches nested events with request context and restores it afterward" do
    described_class.with_context(request_id: "request-1", idempotency_key: "key-1") do
      described_class.add_context(user_id: "user-1")
      described_class.trace(boundary: "data", operation: "query") { :ok }
    end

    expect(events).to all include(
      request_id: "request-1",
      idempotency_key: "key-1",
      user_id: "user-1"
    )
    expect(described_class.context).to eq({})
    expect(described_class.active?).to be(false)
  end

  it "does not add context outside an active context" do
    expect {
      described_class.add_context(user_id: "user-1")
    }.not_to change { RequestStore.store[described_class::CONTEXT_KEY] }

    expect(described_class.context).to eq({})
  end

  it "restores a prior request context even when the block raises" do
    prior_context = {request_id: "prior"}
    RequestStore.store[described_class::CONTEXT_KEY] = prior_context

    expect {
      described_class.with_context(request_id: "temporary") { raise "failure" }
    }.to raise_error("failure")

    expect(described_class.context).to equal(prior_context)
  end

  it "symbolizes keys and drops fields outside the centralized safe schema" do
    sanitized = described_class.sanitize(
      "resource" => "patients",
      "patient_name" => "private"
    )

    expect(sanitized).to eq(resource: "patients")
    expect(described_class::SAFE_FIELDS).to include(:resource)
  end

  it "does not alter the operation result when publication and logging fail" do
    allow(ActiveSupport::Notifications).to receive(:instrument).and_raise("notification failure")
    allow(Rails.logger).to receive(:error).and_raise("logger failure")

    result = described_class.trace(boundary: "data", operation: "query") { :result }

    expect(result).to eq(:result)
  end

  it "preserves the exact operation exception when publication and logging fail" do
    operation_error = RuntimeError.new("operation failure")
    expect(ActiveSupport::Notifications)
      .to receive(:instrument).twice.and_raise("notification failure")
    expect(Rails.logger).to receive(:error).twice.and_raise("logger failure")

    expect {
      described_class.trace(boundary: "data", operation: "query") { raise operation_error }
    }.to raise_error { |raised| expect(raised).to equal(operation_error) }
  end
end
