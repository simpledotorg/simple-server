require "rails_helper"
require "sidekiq/testing"
Sidekiq::Testing.fake!

describe Dhis2::EthiopiaExporter do
  describe ".export" do
    it "queues an EthiopiaExporterJob for each DHIS2 facility present" do
      total_dhis2_facilities = 2
      create_list(:facility, total_dhis2_facilities, :dhis2)

      expect do
        described_class.export
      end.to change(Dhis2::EthiopiaExporterJob.jobs, :size).by(total_dhis2_facilities)
    end
  end
end
