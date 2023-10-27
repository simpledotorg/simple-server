require "rails_helper"
require "sidekiq/testing"
Sidekiq::Testing.fake!

describe Dhis2::EthiopiaExporter do
  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/ethiopia-production.yml"
  end

  describe ".export" do
    it "queues an EthiopiaExporterJob for each DHIS2 facility present" do
      total_dhis2_facilities = 2
      create_list(:facility, total_dhis2_facilities, :dhis2)

      expect do
        described_class.export
      end.to change(Dhis2::EthiopiaExporterJob.jobs, :size).by(total_dhis2_facilities)
    end

    it "passes safely serializable arguments to each job" do
      data_elements = CountryConfig.dhis2_data_elements
        .fetch(:dhis2_data_elements)
        .stringify_keys
      facility1, facility2 = create_list(:facility, 2, :dhis2)
      facility_business_id1 = facility1.business_identifiers.first.id
      facility_business_id2 = facility2.business_identifiers.first.id
      previous_months = 24

      expect(Dhis2::EthiopiaExporterJob).to receive(:perform_async).with(
        data_elements,
        facility_business_id1,
        previous_months
      )
      expect(Dhis2::EthiopiaExporterJob).to receive(:perform_async).with(
        data_elements,
        facility_business_id2,
        previous_months
      )
      described_class.export
    end
  end
end
