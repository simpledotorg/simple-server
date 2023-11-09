module Dhis2
  class BangladeshDisaggregatedExporterJob < Dhis2ExporterJob
    STEP = 5
    BUCKETS = (15..75).step(STEP).to_a

    def perform(facility_identifier_id, total_months)
      facility_identifier = FacilityBusinessIdentifier.find(facility_identifier_id)
      periods = Dhis2::Helpers.last_n_month_periods(total_months)
      export_data = []
      periods.each do |period|
        facility_data_for_period = facility_data_for_period(facility_identifier, period)
        export_data << Dhis2::Helpers.format_disaggregated_facility_period_data(
          facility_data_for_period,
          facility_identifier,
          period,
          @data_elements_map,
          @category_option_combo_ids
        )
      end

      export(export_data.flatten)
      Rails.logger.info("Dhis2::BangladeshDisaggregatedExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    private

    def facility_data_for_period(facility_identifier, period)
      region = facility_identifier.facility.region
      {
        htn_cumulative_assigned_patients: PatientStates::Hypertension::CumulativeAssignedPatientsQuery.new(region, period).call,
        htn_controlled_patients: PatientStates::Hypertension::ControlledPatientsQuery.new(region, period).call,
        htn_uncontrolled_patients: PatientStates::Hypertension::UncontrolledPatientsQuery.new(region, period).call,
        htn_patients_who_missed_visits: PatientStates::Hypertension::MissedVisitsPatientsQuery.new(region, period).call,
        htn_patients_lost_to_follow_up: PatientStates::Hypertension::LostToFollowUpPatientsQuery.new(region, period).call,
        htn_dead_patients: PatientStates::Hypertension::DeadPatientsQuery.new(region, period).call,
        htn_cumulative_registered_patients: PatientStates::Hypertension::CumulativeRegistrationsQuery.new(region, period).call,
        htn_monthly_registered_patients: PatientStates::Hypertension::MonthlyRegistrationsQuery.new(region, period).call,
        htn_cumulative_assigned_patients_adjusted: PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(region, period).call
      }.transform_values { |patient_states| Dhis2::Helpers.disaggregate_by_gender_age(patient_states, BUCKETS) }
    end
  end
end
