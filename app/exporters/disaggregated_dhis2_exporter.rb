class DisaggregatedDhis2Exporter
  STEP = 5
  BUCKETS = (15..75).step(STEP).to_a

  def self.export
    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: (current_month_period.advance(months: -24)..current_month_period),
      data_elements_map: CountryConfig.current.fetch(:disaggregated_dhis2_data_elements)
    )
    exporter.export do |facility_identifier, period|
      region = facility_identifier.facility.region
      {
        htn_cumulative_assigned_patients: cleanup(disaggregated_counts(PatientStates::CumulativeAssignedPatientsQuery.new(
                                                                         region, period
                                                                       ))),
        htn_controlled_patients: cleanup(disaggregated_counts(PatientStates::ControlledPatientsQuery.new(region,
                                                                                                         period))),
        htn_uncontrolled_patients: cleanup(disaggregated_counts(PatientStates::UncontrolledPatientsQuery.new(region,
                                                                                                             period))),
        htn_patients_who_missed_visits: cleanup(disaggregated_counts(PatientStates::MissedVisitsPatientsQuery.new(
                                                                       region, period
                                                                     ))),
        htn_patients_lost_to_follow_up: cleanup(disaggregated_counts(PatientStates::LostToFollowUpPatientsQuery.new(
                                                                       region, period
                                                                     ))),
        htn_dead_patients: cleanup(disaggregated_counts(PatientStates::DeadPatientsQuery.new(region, period))),
        htn_cumulative_registered_patients: cleanup(disaggregated_counts(PatientStates::CumulativeRegistrationsQuery.new(
                                                                           region, period
                                                                         ))),
        htn_monthly_registered_patients: cleanup(disaggregated_counts(PatientStates::MonthlyRegistrationsQuery.new(
                                                                        region, period
                                                                      ))),
        htn_cumulative_assigned_patients_adjusted: PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
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

  def self.cleanup(disaggregated_values)
    disaggregated_values.transform_keys do |disaggregated_counts_key|
      disaggregated_counts_key[0] +
        '_' +
        BUCKETS[disaggregated_counts_key[1] - 1].to_s +
        '_' +
        (BUCKETS[disaggregated_counts_key[1] - 1] + STEP - 1).to_s
    end
  end

  def self.current_month_period
    @current_month_period ||= Period.current.previous
  end
end
