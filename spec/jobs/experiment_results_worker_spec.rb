require "rails_helper"

RSpec.describe ExperimentResultsExportWorker, type: :model do
  describe "#perform" do
    it "sends the email successfully" do
      experiment = create(:experiment)
      export_double = instance_double(Experimentation::Export)
      expect(Experimentation::Export).to receive(:new).with(experiment).and_return(export_double)
      expect(export_double).to receive(:write_csv)

      described_class.perform_async(experiment.name)
      described_class.drain
    end
  end
end
