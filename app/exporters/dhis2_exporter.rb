require "dhis2"

class Dhis2Exporter
  attr_reader :facility_identifiers, :periods, :data_elements_map, :category_option_combo_ids

  def initialize(data_elements_map:, facility_identifiers: [], periods: [], category_option_combo_ids: [])
    throw "DHIS2 export not enabled in Flipper" unless Flipper.enabled?(:dhis2_export)

    @facility_identifiers = facility_identifiers
    @periods = periods
    @data_elements_map = data_elements_map
    @category_option_combo_ids = category_option_combo_ids

    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def export
    @facility_identifiers.each do |facility_identifier|
      data_values = []
      @periods.each do |period|
        facility_data = yield(facility_identifier, period)
        facility_data.each do |data_element, value|
          data_values << {
            data_element: data_elements_map[data_element],
            org_unit: facility_identifier.identifier,
            period: reporting_period(period),
            value: value
          }
          puts "Adding data for #{facility_identifier.facility.name}, #{period}, #{data_element}: #{data_values.last}"
        end
      end
      send_data_to_dhis2(data_values)
    end
  end

  def export_disaggregated
    @facility_identifiers.each do |facility_identifier|
      data_values = []
      @periods.each do |period|
        facility_data = yield(facility_identifier, period)
        facility_data.each do |data_element, value|
          results = disaggregate_data_values(data_elements_map[data_element], facility_identifier, period, value)
          data_values << results
          results.each { |result| puts "Adding data for #{facility_identifier.facility.name}, #{period}, #{data_element}: #{result}" }
        end
      end
      data_values = data_values.flatten
      send_data_to_dhis2(data_values)
    end
  end

  def send_data_to_dhis2(data_values)
    pp Dhis2.client.data_value_sets.bulk_create(data_values: data_values)
  end

  def disaggregate_data_values(data_element_id, facility_identifier, period, values)
    category_option_combo_ids.map do |combo, id|
      {
        data_element: data_element_id,
        org_unit: facility_identifier.identifier,
        category_option_combo: id,
        period: reporting_period(period),
        value: values.with_indifferent_access[combo] || 0
      }
    end
  end

  def reporting_period(month_period)
    if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
      EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
    else
      month_period.to_s(:dhis2)
    end
  end

  def format_facility_period_data(facility_identifier, period, facility_data, data_elements_map)
    formatted_facility_data = []
    facility_data.each do |data_element, value|
      formatted_facility_data << {
        data_element: data_elements_map[data_element],
        org_unit: facility_identifier.identifier,
        period: reporting_period(period),
        value: value
      }
    end
  end
end
