class Dhis2Exporter
  require "dhis2"

  attr_reader :facility_identifiers, :periods, :data_elements_map

  def initialize(facility_identifiers:, periods:, data_elements_map:)
    @facility_identifiers = facility_identifiers
    @periods = periods
    @data_elements_map = data_elements_map

    Dhis2.configure do |config|
      config.url = ENV.fetch("DHIS2_URL")
      config.user = ENV.fetch("DHIS2_USERNAME")
      config.password = ENV.fetch("DHIS2_PASSWORD")
      config.version = ENV.fetch("DHIS2_VERSION")
    end
  end

  def export
    @facility_identifiers.each do |facility_identifier|
      @periods.each do |period|
        data_values = yield(facility_identifier, period)
      end

      send_data_to_dhis2(data_values)
    end
  end

  def send_data_to_dhis2(data_values)
    pp Dhis2.client.data_value_sets.bulk_create(data_values: data_values)
  end

  def export
    export_values = []
    @facility_identifiers.each do |facility_identifier|
      @periods.each do |period|
        facility_data = yield(facility_identifier, period)
        facility_data.each do |data_element, value|
          data_element_id = data_elements_map[data_element]
          export_values << if CountryConfig.current.fetch(:dhis2_category_option_combo).exists?
                             disaggregate_export_values(facility_identifier, period, value)
                             # array of maps
                           else
                             # single map
                             {
                               data_element: data_element_id,
                               org_unit: facility_identifier.identifier,
                               period: reporting_period(period),
                               value: value
                             }
                           end
          export_values.flatten
          puts "Adding data for #{facility_identifier.facility.name}, #{period}, #{data_element}: #{export_values.last}"
        end
      end

    end
  end

  def self.disaggregate_export_values(facility_identifier, period, values)
    category_option_combo_ids = CountryConfig.current.fetch(:dhis2_category_option_combo)
    category_option_combo_ids.map do |name, id|
      value = 0
      value = values[name] if values.has_key?(name)
      {
        data_element: data_elements_map[data_element],
        org_unit: facility_identifier.identifier,
        category_option_combo: id,
        period: reporting_period(period),
        value: value
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
end
