require "rails_helper"
require_relative "./experiment_data_examples.rb"

RSpec.describe Experimentation::DataExportWorker, type: :model do
  describe "#as_csv" do
    include_context "active experiment data"

    it "exports accurate data in the expected format" do
      described_class.perform_async(@experiment.name, "person@example.com")
      described_class.drain

      pp parsed

      # csv_data = subject.mail_csv
      # csv_data.attachments.to_json
    end
  end
end
