module Dhis2
  class BangladeshExporterJob < Dhis2ExporterJob
    def perform(facility_identifier_id, total_months)
      facility_identifier = FacilityBusinessIdentifier.find(facility_identifier_id)
      periods = last_n_month_periods(total_months)
      facility_data = []

      periods.map do |period|
        facility_data_for_period = facility_data_for_period(facility_identifier, period)
        facility_data << format_facility_period_data(
          facility_data_for_period,
          facility_identifier,
          period
        )
      end

      export(facility_data.flatten)
      Rails.logger.info("Dhis2::BangladeshExporterJob for facility identifier #{facility_identifier} succeeded.")
    end

    private

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
  end
end
