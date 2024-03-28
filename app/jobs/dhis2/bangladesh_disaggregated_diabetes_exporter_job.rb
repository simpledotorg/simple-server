# frozen_string_literal: true

module Dhis2
  class BangladeshDisaggregatedDiabetesExporterJob < Dhis2ExporterJob
    MIN_AGE = 15
    MAX_AGE = 75
    AGE_BUCKET_SIZE = 5

    private

    def facility_data_for_period(region, period)
      {
        dm_cumulative_assigned: PatientStates::Diabetes::CumulativeAssignedPatientsQuery.new(region, period).call,
        # htn_controlled: PatientStates::Hypertension::ControlledPatientsQuery.new(region, period).call,
        # htn_uncontrolled: PatientStates::Hypertension::UncontrolledPatientsQuery.new(region, period).call,
        dm_missed_visits: PatientStates::Diabetes::MissedVisitsPatientsQuery.new(region, period).call,
        dm_ltfu: PatientStates::Diabetes::LostToFollowUpPatientsQuery.new(region, period).call,
        # htn_dead: PatientStates::Hypertension::DeadPatientsQuery.new(region, period).call,
        # htn_cumulative_registrations: PatientStates::Hypertension::CumulativeRegistrationsQuery.new(region, period).call,
        # htn_monthly_registrations: PatientStates::Hypertension::MonthlyRegistrationsQuery.new(region, period).call,
        dm_cumulative_assigned_adjusted: PatientStates::Diabetes::AdjustedAssignedPatientsQuery.new(region, period).call
      }.transform_values { |patient_states| disaggregate_by_gender_age(patient_states, data_buckets(MIN_AGE, MAX_AGE, AGE_BUCKET_SIZE)) }
    end

    def data_elements_map
      CountryConfig.dhis2_data_elements.fetch(:disaggregated_diabetes_dhis2_data_elements)
    end

    def category_option_combo_ids
      CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo)
    end

    def format_facility_period_data(facility_data, facility_identifier, period)
      formatted_facility_data = []
      facility_data.each do |data_element, values|
        category_option_combo_ids.each do |combo, id|
          formatted_facility_data << {
            data_element: data_elements_map[data_element],
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
