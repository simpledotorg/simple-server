module Dhis2
  class EthiopiaExporterJob < Dhis2ExporterJob
    private

    def facility_data_for_period(region, period)
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

    def data_elements_map
      CountryConfig.dhis2_data_elements.fetch(:dhis2_data_elements)
    end
  end
end
