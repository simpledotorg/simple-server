# frozen_string_literal: true

module Dhis2
  class BangladeshDisaggregatedExporterJob < Dhis2ExporterJob
    STEP = 5
    BUCKETS = (15..75).step(STEP).to_a

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
      Rails.logger.info("Dhis2::BangladeshDisaggregatedExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    private

    def facility_data_for_period(facility_identifier, period)
      region = Region.find_by(source_id: facility_identifier.facility_id)
      {
        htn_cumulative_assigned: PatientStates::Hypertension::CumulativeAssignedPatientsQuery.new(region, period).call,
        htn_controlled: PatientStates::Hypertension::ControlledPatientsQuery.new(region, period).call,
        htn_uncontrolled: PatientStates::Hypertension::UncontrolledPatientsQuery.new(region, period).call,
        htn_missed_visits: PatientStates::Hypertension::MissedVisitsPatientsQuery.new(region, period).call,
        htn_ltfu: PatientStates::Hypertension::LostToFollowUpPatientsQuery.new(region, period).call,
        htn_dead: PatientStates::Hypertension::DeadPatientsQuery.new(region, period).call,
        htn_cumulative_registrations: PatientStates::Hypertension::CumulativeRegistrationsQuery.new(region, period).call,
        htn_monthly_registrations: PatientStates::Hypertension::MonthlyRegistrationsQuery.new(region, period).call,
        htn_cumulative_assigned_adjusted: PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(region, period).call
      }.transform_values { |patient_states| Dhis2::Helpers.disaggregate_by_gender_age(patient_states, BUCKETS) }
    end

    def config
      {
        data_elements_map: CountryConfig.dhis2_data_elements.fetch(:disaggregated_dhis2_data_elements),
        category_option_combo_ids: CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo)
      }
    end

    def format_facility_period_data(facility_data, facility_identifier, period)
      formatted_facility_data = []
      facility_data.each do |data_element, values|
        config.fetch(:category_option_combo_ids).each do |combo, id|
          formatted_facility_data << {
            data_element: config.fetch(:data_elements_map)[data_element],
            org_unit: facility_identifier.identifier,
            category_option_combo: id,
            period: reporting_period(period),
            value: values.with_indifferent_access[combo] || 0
          }
        end
      end
      formatted_facility_data
    end
  end
end
