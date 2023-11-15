require "dhis2"

module Dhis2
  class Dhis2ExporterJob
    include Sidekiq::Job
    sidekiq_options queue: :default

    attr_reader :configuration, :client

    def initialize
      throw "DHIS2 export not enabled in Flipper" unless Flipper.enabled?(:dhis2_export)

      @configuration = Dhis2::Configuration.new.tap do |config|
        config.url = ENV.fetch("DHIS2_URL")
        config.user = ENV.fetch("DHIS2_USERNAME")
        config.password = ENV.fetch("DHIS2_PASSWORD")
        config.version = ENV.fetch("DHIS2_VERSION")
      end
      @client = Dhis2::Client.new(@configuration.client_params)
    end

    def perform(facility_identifier_id, total_months)
      facility_identifier = FacilityBusinessIdentifier.find(facility_identifier_id)
      region = Region.find_by!(source_id: facility_identifier.facility_id)
      periods = last_n_month_periods(total_months)
      export_data = []
      periods.each do |period|
        facility_data_for_period = facility_data_for_period(region, period)
        export_data << format_facility_period_data(
          facility_data_for_period,
          facility_identifier,
          period
        )
      end
      export(export_data.flatten)
      Rails.logger.info("Dhis2::Dhis2ExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    def facility_data_for_period(_region, _period)
      {}
    end

    def export(data_values)
      # TODO error handling and logging
      response = @client.data_value_sets.bulk_create(data_values: data_values)
      Rails.logger.info("Exported to Dhis2 successfully", response)
    end

    def disaggregate_by_gender_age(patient_states, buckets)
      gender_age_counts(patient_states, buckets).transform_keys do |(gender, age_bucket_index)|
        gender_age_range_key(gender, buckets, age_bucket_index)
      end
    end

    private

    def format_facility_period_data(facility_data, facility_identifier, period)
      formatted_facility_data = []
      facility_data.each do |data_element, value|
        formatted_facility_data << {
          data_element: data_elements_map[data_element],
          org_unit: facility_identifier.identifier,
          period: reporting_period(period),
          value: value
        }
      end
      formatted_facility_data
    end

    def last_n_month_periods(n)
      (Period.current.advance(months: -n)..Period.current.previous)
    end

    def reporting_period(month_period)
      if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
        EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
      else
        month_period.to_s(:dhis2)
      end
    end

    def gender_age_counts(patient_states, buckets)
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
        buckets,
        PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(patient_states)
      ).count
    end

    def gender_age_range_key(gender, buckets, age_bucket_index)
      age_range_start = buckets[age_bucket_index - 1]
      if age_range_start == buckets.last
        "#{gender}_#{age_range_start}_plus"
      else
        age_range_end = buckets[age_bucket_index] - 1
        "#{gender}_#{age_range_start}_#{age_range_end}"
      end
    end
  end
end
