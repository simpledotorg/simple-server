require "rails_helper"
require_relative Rails.root.join("spec/support/experiment_data_examples.rb")

RSpec.describe ExperimentResultsExportWorker, type: :model do
  describe "#perform" do
    it "sends the email successfully" do
      experiment = create(:experiment)
      csv_double = double("csv")
      mail_double = double("mailer")
      export_double = instance_double(Experimentation::Export, as_csv: csv_double)
      expect(Experimentation::Export).to receive(:new).with(experiment).and_return(export_double)
      expect(ExperimentResultsMailer).to receive(:new).with(csv_double, experiment.name, "person@example.com").and_return(mail_double)
      expect(mail_double).to receive(:deliver_csv)

      described_class.perform_async(experiment.name, "person@example.com")
      described_class.drain
    end
  end
end
