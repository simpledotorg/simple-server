require 'rails_helper'

describe Dhis2::EthiopiaExporterJob do
  before(:each) do
    Flipper.enable(:dhis2_export)
  end

  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/ethiopia-production.yml"
  end

  describe ".export" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements) }
    let(:facilities) { create_list(:facility, 2, :dhis2) }
    let(:export_values) {
      {
        htn_controlled: :htn_controlled,
        htn_cumulative_assigned: :htn_cumulative_assigned,
        htn_cumulative_assigned_adjusted: :htn_cumulative_assigned_adjusted,
        htn_cumulative_registrations: :htn_cumulative_registrations,
        htn_dead: :htn_dead,
        htn_monthly_registrations: :htn_monthly_registrations,
        htn_ltfu: :htn_ltfu,
        htn_missed_visits: :htn_missed_visits,
        htn_uncontrolled: :htn_uncontrolled
      }
    }

    it "exports metrics for the given facility for the last given number of months to dhis2 in Ethiopia" do
      facility = facilities.first
      total_months = 2
      exporter = Dhis2::EthiopiaExporterJob
      periods = described_class.new.export_periods(total_months)

      export_data = {}

      expect_any_instance_of(Dhis2Exporter).to receive(:send_data_to_dhis2).with(export_data)

      described_class.perform_async(
        data_elements.stringify_keys,
        facility.id,
        total_months
      )
    end
  end
end
