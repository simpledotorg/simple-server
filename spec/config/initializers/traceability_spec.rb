require "rails_helper"

RSpec.describe "Traceability subscriber wiring" do
  it "attempts metrics and preserves the traced result when logging and failure reporting raise" do
    subscriber_error = RuntimeError.new("secret subscriber message")
    allow(Traceability::LogSubscriber).to receive(:call).and_raise(subscriber_error)
    allow(Traceability::MetricsSubscriber).to receive(:call)
    expect(Rails.logger).to receive(:error).with(
      msg: "traceability_subscriber_error",
      subscriber_class: "Traceability::LogSubscriber",
      error_class: "RuntimeError"
    ).twice.and_raise("logger failure")

    result = Traceability.trace(boundary: "data", operation: "query") { :result }

    expect(result).to eq(:result)
    expect(Traceability::MetricsSubscriber).to have_received(:call).twice
  end

  it "attempts logging when metrics raise" do
    allow(Traceability::LogSubscriber).to receive(:call)
    allow(Traceability::MetricsSubscriber).to receive(:call).and_raise("metrics failure")
    allow(Rails.logger).to receive(:error)

    result = Traceability.trace(boundary: "data", operation: "query") { :result }

    expect(result).to eq(:result)
    expect(Traceability::LogSubscriber).to have_received(:call).twice
  end
end
