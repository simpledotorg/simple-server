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
      periods = last_n_month_periods(total_months)
      export_data = []
      periods.each do |period|
        facility_data_for_period = facility_data_for_period(facility_identifier, period)
        export_data << format_facility_period_data(
          facility_data_for_period,
          facility_identifier,
          period
        )
      end
      export(export_data.flatten)
      Rails.logger.info("Dhis2::Dhis2ExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    def facility_data_for_period(facility_identifier, period)
      region = Region.find_by(source_id: facility_identifier.facility_id)
      {
        htn_cumulative_assigned: PatientStates::Hypertension::CumulativeAssignedPatientsQuery.new(region, period).call.count,
        htn_controlled: PatientStates::Hypertension::ControlledPatientsQuery.new(region, period).call.count,
        htn_uncontrolled: PatientStates::Hypertension::UncontrolledPatientsQuery.new(region, period).call.count,
        htn_missed_visits: PatientStates::Hypertension::MissedVisitsPatientsQuery.new(region, period).call.count,
        htn_ltfu: PatientStates::Hypertension::LostToFollowUpPatientsQuery.new(region, period).call.count,
        htn_dead: PatientStates::Hypertension::DeadPatientsQuery.new(region, period).call.count,
        htn_cumulative_registrations: PatientStates::Hypertension::CumulativeRegistrationsQuery.new(region, period).call.count,
        htn_monthly_registrations: PatientStates::Hypertension::MonthlyRegistrationsQuery.new(region, period).call.count,
        htn_cumulative_assigned_adjusted: PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(region, period).call.count
      }
    end

    def config
      {
        data_elements_map: CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
      }
    end

    def last_n_month_periods(n)
      (Period.current.advance(months: -n)..Period.current.previous)
    end

    def format_facility_period_data(facility_data, facility_identifier, period)
      formatted_facility_data = []
      facility_data.each do |data_element, value|
        formatted_facility_data << {
          data_element: config.fetch(:data_elements_map)[data_element],
          org_unit: facility_identifier.identifier,
          period: reporting_period(period),
          value: value
        }
      end
      formatted_facility_data
    end

    def reporting_period(month_period)
      if Flipper.enabled?(:dhis2_use_ethiopian_calendar)
        EthiopiaCalendarUtilities.gregorian_month_period_to_ethiopian(month_period).to_s(:dhis2)
      else
        month_period.to_s(:dhis2)
      end
    end

    def export(data_values)
      response = @client.data_value_sets.bulk_create(data_values: data_values)
      Rails.logger.info("Exported to Dhis2 successfully", response)
    end
  end
end
