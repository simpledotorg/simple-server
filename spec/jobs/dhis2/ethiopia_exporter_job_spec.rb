require "rails_helper"
require "sidekiq/testing"
require "dhis2"
Sidekiq::Testing.inline!

describe Dhis2::EthiopiaExporterJob do
  before do
    ENV["DHIS2_DATA_ELEMENTS_FILE"] = "config/data/dhis2/ethiopia-production.yml"
    Flipper.enable(:dhis2_export)
    Flipper.enable(:dhis2_use_ethiopian_calendar)
  end

  describe ".perform" do
    let(:data_elements) { CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements) }
    let(:facilities) { create_list(:facility, 2, :dhis2) }
    let(:facility_data) {
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

    it "exports metrics required by Ethiopia for the given facility for the last given number of months to DHIS2" do
      facility_identifier = create(:facility_business_identifier)
      total_months = 2
      periods = Dhis2::Helpers.last_n_month_periods(total_months)
      export_data = []

      periods.each do |period|
        facility_data.each do |data_element, value|
          allow(Dhis2::Helpers).to receive(data_element).with(facility_identifier.facility.region, period).and_return(value)

          export_data << {
            data_element: data_elements[data_element],
            org_unit: facility_identifier.identifier,
            period: EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(period).to_s(:dhis2),
            value: value
          }
        end
      end

      data_value_sets = double
      dhis2_client = double
      allow(Dhis2).to receive(:client).and_return(dhis2_client)
      allow(dhis2_client).to receive(:data_value_sets).and_return(data_value_sets)
      expect(data_value_sets).to receive(:bulk_create).with(data_values: export_data.flatten)

      Sidekiq::Testing.inline! do
        Dhis2::EthiopiaExporterJob.perform_async(
          facility_identifier.id,
          total_months
        )
      end
    end
  end
end
