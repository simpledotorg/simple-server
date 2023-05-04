require "rails_helper"

describe Dhis2Exporter do
  let(:facilities) { create_list(:facility, 2) }
  let(:facility_identifiers) {
    facilities.map do |facility|
      create(:facility_business_identifier, facility: facility)
    end.to_a
  }
  let(:periods) { (Period.current.previous.advance(months: -1)..Period.current.previous).to_a }
  let(:data_elements_map) { {indicator1: "indicator id 1", indicator2: "indicator id 2"} }
  let(:category_option_combo_ids) { {category_option_combo1: "combo id 1", category_option_combo2: "combo id 2"} }

  before(:each) do
    Flipper.enable(:dhis2_export)
  end

  describe "#export" do
    it "sends data element values for all facilities, given facility identifiers, periods and data elements" do
      exporter = described_class.new(
        facility_identifiers: facility_identifiers,
        periods: periods,
        data_elements_map: data_elements_map
      )
      dummy_value = 0
      expected_data_values = facility_identifiers.map { |facility_identifier|
        periods.product(data_elements_map.values).map { |period, data_element_id|
          {
            data_element: data_element_id,
            org_unit: facility_identifier.identifier,
            period: exporter.reporting_period(period),
            value: dummy_value
          }
        }
      }

      allow(exporter).to receive(:send_data_to_dhis2)

      expect(exporter).to receive(:send_data_to_dhis2).with(expected_data_values.first)
      expect(exporter).to receive(:send_data_to_dhis2).with(expected_data_values.second)

      exporter.export do |_facility_identifier, _period|
        {
          data_elements_map.keys.first => dummy_value,
          data_elements_map.keys.second => dummy_value
        }
      end
    end
  end

  describe "#export_disaggregated" do
    it "sends disaggregated data element values for all facilities, given facility identifiers, periods and data elements" do
      exporter = described_class.new(
        facility_identifiers: facility_identifiers,
        periods: periods,
        data_elements_map: data_elements_map,
        category_option_combo_ids: category_option_combo_ids
      )
      dummy_value = 0
      expected_data_values = facility_identifiers.map do |facility_identifier|
        periods.product(data_elements_map.values).map do |period, data_element_id|
          category_option_combo_ids.map do |_combo, id|
            {
              data_element: data_element_id,
              org_unit: facility_identifier.identifier,
              category_option_combo: id,
              period: exporter.reporting_period(period),
              value: dummy_value
            }
          end
        end.flatten
      end
      disaggregated_data_values = category_option_combo_ids.transform_values { |_value| dummy_value }

      allow(exporter).to receive(:send_data_to_dhis2)

      expect(exporter).to receive(:send_data_to_dhis2).with(expected_data_values.first)
      expect(exporter).to receive(:send_data_to_dhis2).with(expected_data_values.second)

      exporter.export_disaggregated do |_facility_identifier, _period|
        {
          data_elements_map.keys.first => disaggregated_data_values,
          data_elements_map.keys.second => disaggregated_data_values
        }
      end
    end
  end

  describe "#disaggregate_data_values" do
    it "should return a list of disaggregated data values for each category-option combo for the given data element and period" do
      dummy_value = 5
      facility_identifier = facility_identifiers.first
      exporter = described_class.new(
        facility_identifiers: [facility_identifier],
        periods: periods,
        data_elements_map: data_elements_map,
        category_option_combo_ids: category_option_combo_ids
      )
      indicator1_disaggregated_values = category_option_combo_ids.transform_values { |_value| dummy_value }
      expected_disaggregated_values = category_option_combo_ids.map do |combo, id|
        {
          data_element: data_elements_map.keys.first,
          org_unit: facility_identifier.identifier,
          category_option_combo: id,
          period: exporter.reporting_period(periods.first),
          value: indicator1_disaggregated_values[combo]
        }
      end

      disaggregated_values = exporter.disaggregate_data_values(
        exporter.data_elements_map.keys.first,
        exporter.facility_identifiers.first,
        exporter.periods.first,
        indicator1_disaggregated_values
      )

      expect(disaggregated_values).to match_array(expected_disaggregated_values)
      disaggregated_values.map do |export_value|
        expect(export_value[:value]).not_to eq(nil)
      end
    end

    it "should set value to zero for category-option combos that don't have values for a given data element" do
      dummy_value = 5
      dummy_period = "dummy2020"
      indicator1_disaggregated_values = {category_option_combo_ids.keys.first => dummy_value}

      exporter = described_class.new(
        facility_identifiers: facility_identifiers,
        periods: periods,
        data_elements_map: data_elements_map,
        category_option_combo_ids: category_option_combo_ids
      )
      allow(exporter).to receive(:reporting_period).and_return(dummy_period)
      disaggregated_values = exporter.disaggregate_data_values(
        exporter.data_elements_map.keys.first,
        exporter.facility_identifiers.first,
        exporter.periods.first,
        indicator1_disaggregated_values
      )

      expect(disaggregated_values.first[:value]).to eq(dummy_value)
      expect(disaggregated_values.second[:value]).to eq(0)
    end
  end

  describe "#reporting_period" do
    it "should format month_date to DHIS2 format by the Ethiopian calendar if Flipper flag is enabled" do
      Flipper.enable(:dhis2_use_ethiopian_calendar)
      expected_month_date = EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(periods.first).to_s(:dhis2)
      exporter = described_class.new(
        facility_identifiers: facility_identifiers,
        periods: periods,
        data_elements_map: data_elements_map
      )

      expect(exporter.reporting_period(periods.first)).to eq(expected_month_date)
    end

    it "should format month_date to DHIS2 format by the Gregorian calendar if Flipper flag is disabled" do
      Flipper.disable(:dhis2_use_ethiopian_calendar)
      expected_month_date = periods.first.to_s(:dhis2)
      exporter = described_class.new(
        facility_identifiers: facility_identifiers,
        periods: periods,
        data_elements_map: data_elements_map
      )

      expect(exporter.reporting_period(periods.first)).to eq(expected_month_date)
    end
  end
end
