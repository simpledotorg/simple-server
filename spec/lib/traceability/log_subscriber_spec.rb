require "rails_helper"

RSpec.describe Traceability::LogSubscriber do
  describe ".call" do
    it "logs request boundaries with the request marker and retains the payload" do
      payload = {
        phase: "finish",
        boundary: "request",
        operation: "sync",
        request_id: "request-1",
        outcome: "success"
      }

      expect(Rails.logger).to receive(:info).with(
        phase: "finish",
        boundary: "request",
        operation: "sync",
        request_id: "request-1",
        outcome: "success",
        msg: "SIMPLE-REQUEST-LINE"
      )

      described_class.call(payload)
    end

    it "logs non-request boundaries with the data marker and retains the payload" do
      payload = {
        phase: "start",
        boundary: "data",
        operation: "merge_batch",
        resource: "patients"
      }

      expect(Rails.logger).to receive(:info).with(
        phase: "start",
        boundary: "data",
        operation: "merge_batch",
        resource: "patients",
        msg: "SIMPLE-DATA-LINE"
      )

      described_class.call(payload)
    end
  end
end
