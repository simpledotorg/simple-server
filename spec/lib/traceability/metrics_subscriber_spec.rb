require "rails_helper"

RSpec.describe Traceability::MetricsSubscriber do
  describe ".call" do
    it "ignores start events" do
      payload = {
        phase: "start",
        boundary: "data",
        operation: "merge_batch",
        resource: "patients"
      }

      expect(Metrics).not_to receive(:increment)
      expect(Metrics).not_to receive(:histogram)

      described_class.call(payload)
    end

    it "records finish counts and duration in seconds with only permitted labels" do
      payload = {
        phase: "finish",
        boundary: "data",
        operation: "merge_batch",
        resource: "patients",
        outcome: "success",
        duration_ms: 125.0,
        request_id: "request-1",
        user_id: "user-1",
        facility_id: "facility-1",
        idempotency_key: "key-1"
      }
      labels = {
        boundary: "data",
        operation: "merge_batch",
        resource: "patients",
        outcome: "success"
      }

      expect(Metrics).to receive(:increment).with("simple_boundary_operations_total", labels)
      expect(Metrics).to receive(:histogram).with("simple_boundary_duration_seconds", 0.125, labels)

      described_class.call(payload)
    end

    it "omits a missing optional resource label" do
      payload = {
        phase: "finish",
        boundary: "request",
        operation: "sync",
        resource: nil,
        outcome: "error",
        duration_ms: 250
      }
      labels = {
        boundary: "request",
        operation: "sync",
        outcome: "error"
      }

      expect(Metrics).to receive(:increment).with("simple_boundary_operations_total", labels)
      expect(Metrics).to receive(:histogram).with("simple_boundary_duration_seconds", 0.25, labels)

      described_class.call(payload)
    end
  end
end
