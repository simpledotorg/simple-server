class DisaggregatedDhis2Exporter
  BUCKETS = (15..75).step(5)

  def self.export
    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: (current_month_period.advance(months: -24)..current_month_period),
      data_elements_map: CountryConfig.current.fetch(:disaggregated_dhis2_data_elements)
    )
    exporter.export do |facility_identifier, period|
      region = facility_identifier.facility.region
      {
        cumulative_assigned: disaggregated_counts(PatientStates::CumulativeAssignedPatientsQuery.new(region, period)),
        controlled: disaggregated_counts(PatientStates::ControlledPatientsQuery.new(region, period)),
        uncontrolled: disaggregated_counts(PatientStates::UncontrolledPatientsQuery.new(region, period)),
        missed_visits: disaggregated_counts(PatientStates::MissedVisitsPatientsQuery.new(region, period)),
        lost_to_follow_up: disaggregated_counts(PatientStates::LostToFollowUpPatientsQuery.new(region, period)),
        dead: disaggregated_counts(PatientStates::DeadPatientsQuery.new(region, period)),
        cumulative_registrations: disaggregated_counts(PatientStates::CumulativeRegistrationsQuery.new(region, period)),
        monthly_registrations: disaggregated_counts(PatientStates::MonthlyRegistrationsQuery.new(region, period)),
        cumulative_assigned_excluding_recent: PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
          BUCKETS,
          PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(
            PatientStates::CumulativeAssignedPatientsQuery.new(region, period).excluding_recent_registrations
          )
        ).count
      }
    end
  end

  def self.disaggregated_counts(query)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      BUCKETS,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(
        query.call
      )
    ).count
  end

  def self.current_month_period
    @current_month_period ||= Period.current.previous
  end
end
