require "rails_helper"

RSpec.describe ImportFacilitiesJob do
  include ActiveJob::TestHelper
  before { FactoryBot.create(:facility) } # needed for our bot import user

  describe "#perform_later" do
    let(:resource) { build_patient_import_resource }
    let(:job) { BulkApiImportJob.perform_later(resources: [resource]) }

    it "queues the job" do
      expect { job }.to have_enqueued_job(BulkApiImportJob).once.on_queue("default")
    end

    it "runs the importer" do
      expect { perform_enqueued_jobs { job } }.to change(Patient, :count).by(1)
    end
  end
end
