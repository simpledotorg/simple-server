require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe ExperimentResultsExportWorker, type: :model do
  describe "#perform" do
    it "sends the email successfully" do
      experiment = create(:experiment)
      csv_double = double("csv")
      export_double = instance_double(Experimentation::Export, as_csv: csv_double)
      expect(Experimentation::Export).to receive(:new).with(experiment).and_return(export_double)
      expect(ExperimentResultsMailer).to receive(:new).with(csv_double, experiment.name, "person@example.com")
      expect_any_instance_of(ExperimentResultsMailer).to receive(:deliver_csv)

      described_class.perform_async(experiment.name, "person@example.com")
      described_class.drain
    end
  end
end
