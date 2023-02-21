class Dhis2Exporter
  require "dhis2"

  attr_reader :facility_identifier, :periods, :data_elements_map

  def initialize(facility_identifiers:, periods:, data_elements_map:)
    @facility_identifier = facility_identifiers
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
    export_values = []
    @facility_identifier.each do |facility_identifier|
      @periods.each do |period|
        facility_data = yield(facility_identifier, period)

        facility_data.each do |data_element, value|
          data_element_id = data_elements_map[data_element]

          export_values << {
            data_element: data_element_id,
            org_unit: facility_identifier.identifier,
            period: reporting_period(period),
            value: value
          }
          puts "Adding data for #{facility_identifier.facility.name}, #{period}, #{data_element}: #{export_values.last}"
        end
      end

      pp Dhis2.client.data_value_sets.bulk_create(data_values: export_values)
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
