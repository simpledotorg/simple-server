module Dhis2
  class BangladeshExporterJob < Dhis2ExporterJob
    private

    def facility_data_for_period(facility_id, period)
      {
        htn_cumulative_assigned: PatientStates::Hypertension::CumulativeAssignedPatientsQuery.new(facility_id, period).call.count,
        htn_controlled: PatientStates::Hypertension::ControlledPatientsQuery.new(facility_id, period).call.count,
        htn_uncontrolled: PatientStates::Hypertension::UncontrolledPatientsQuery.new(facility_id, period).call.count,
        htn_missed_visits: PatientStates::Hypertension::MissedVisitsPatientsQuery.new(facility_id, period).call.count,
        htn_ltfu: PatientStates::Hypertension::LostToFollowUpPatientsQuery.new(facility_id, period).call.count,
        htn_dead: PatientStates::Hypertension::DeadPatientsQuery.new(facility_id, period).call.count,
        htn_cumulative_registrations: PatientStates::Hypertension::CumulativeRegistrationsQuery.new(facility_id, period).call.count,
        htn_monthly_registrations: PatientStates::Hypertension::MonthlyRegistrationsQuery.new(facility_id, period).call.count,
        htn_cumulative_assigned_adjusted: PatientStates::Hypertension::AdjustedAssignedPatientsQuery.new(facility_id, period).call.count
      }
    end

    def data_elements_map
      CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    end
  end
end
