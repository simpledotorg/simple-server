require "rails_helper"

RSpec.describe BulkApiImportJob do
  include ActiveJob::TestHelper
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#perform_later" do
    let(:resource) { build_condition_import_resource }
    let(:job) { described_class.perform_later(resources: [resource], organization_id: "org_id") }

    it "queues the job" do
      expect { job }.to have_enqueued_job(described_class).once.on_queue("default")
    end

    it "runs the importer" do
      expect { perform_enqueued_jobs { job } }.to change(MedicalHistory, :count).by(1)
    end
  end
end
