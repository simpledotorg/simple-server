require "rails_helper"
require "dhis2"

describe Dhis2::EthiopiaExporter do
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

    it "exports simple metrics for the last 24 months to dhis2 in ethiopia" do
      current_month_period = Period.current.previous
      periods = (current_month_period.advance(months: -24)..current_month_period)

      export_values.each do |key, value|
        allow(Dhis2::Helpers).to receive(key).and_return(value)
      end

      business_identifiers = facilities.flat_map { |facility| facility.business_identifiers.dhis2_org_unit_id }
      expected_values = business_identifiers.map do |business_identifier|
        periods.flat_map do |period|
          export_values.keys.map do |key|
            {
              data_element: data_elements[key],
              org_unit: business_identifier.identifier,
              period: period.to_s(:dhis2),
              value: export_values[key]
            }
          end
        end
      end

      data_value_sets = double
      allow(Dhis2.client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: expected_values[0])
      expect(data_value_sets).to receive(:bulk_create).with(data_values: expected_values[1])
      Dhis2::EthiopiaExporter.export
    end
  end
end
