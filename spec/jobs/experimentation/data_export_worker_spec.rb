require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe Experimentation::DataExportWorker, type: :model do
  describe "#perform" do
    include_context "active experiment data"

    it "sends the email successfully" do
      expect(ExperimentResultsMailer).to receive(:new).with(@experiment.name, "person@example.com").and_call_original
      expect_any_instance_of(ExperimentResultsMailer).to receive(:mail_csv)

      described_class.perform_async(@experiment.name, "person@example.com")
      described_class.drain
    end
  end
end
