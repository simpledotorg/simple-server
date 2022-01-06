# frozen_string_literal: true

require "rails_helper"

RSpec.describe PatientLookupAuditLogJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform_later" do
    it "queues the job on low" do
      expect {
        described_class.perform_async({some: :hash}.to_json)
      }.to change(Sidekiq::Queues["low"], :size).by(1)
      described_class.clear
    end

    it "writes to a log file" do
      Sidekiq::Testing.inline! do
        expect(PatientLookupAuditLogger).to receive(:info).with({some: :hash}.to_json)
      end
      described_class.perform_async({some: :hash}.to_json)
      described_class.drain
    end
  end
end
