class BangladeshDisaggregatedDhis2Exporter
  STEP = 5
  BUCKETS = (15..75).step(STEP).to_a

  def self.export
    exporter = Dhis2Exporter.new(
      facility_identifiers: FacilityBusinessIdentifier.dhis2_org_unit_id,
      periods: (current_month_period.advance(months: -24)..current_month_period),
      data_elements_map: CountryConfig.current.fetch(:disaggregated_dhis2_data_elements),
      category_option_combo_ids: CountryConfig.current.fetch(:dhis2_category_option_combo)
    )

    exporter.export_disaggregated do |facility_identifier, period|
      region = facility_identifier.facility.region
      {
        htn_cumulative_assigned_patients: PatientStates::CumulativeAssignedPatientsQuery.new(region, period).call,
        htn_controlled_patients: PatientStates::ControlledPatientsQuery.new(region, period).call,
        htn_uncontrolled_patients: PatientStates::UncontrolledPatientsQuery.new(region, period).call,
        htn_patients_who_missed_visits: PatientStates::MissedVisitsPatientsQuery.new(region, period).call,
        htn_patients_lost_to_follow_up: PatientStates::LostToFollowUpPatientsQuery.new(region, period).call,
        htn_dead_patients: PatientStates::DeadPatientsQuery.new(region, period).call,
        htn_cumulative_registered_patients: PatientStates::CumulativeRegistrationsQuery.new(region, period).call,
        htn_monthly_registered_patients: PatientStates::MonthlyRegistrationsQuery.new(region, period).call,
        htn_cumulative_assigned_patients_adjusted: PatientStates::AdjustedAssignedPatientsQuery.new(region, period).call
      }.transform_values { |patient_states| disaggregate_by_gender_age(patient_states) }
    end
  end

  def self.disaggregate_by_gender_age(patient_states)
    gender_age_counts(patient_states).transform_keys do |(gender, age_bucket_index)|
      gender_age_range_key(gender, age_bucket_index)
    end
  end

  def self.gender_age_counts(patient_states)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      BUCKETS,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(patient_states)
    ).count
  end

  def self.gender_age_range_key(gender, age_bucket_index)
    age_range_start = BUCKETS[age_bucket_index - 1]
    if age_range_start == BUCKETS.last
      "#{gender}_#{age_range_start}_plus"
    else
      age_range_end = BUCKETS[age_bucket_index] - 1
      "#{gender}_#{age_range_start}_#{age_range_end}"
    end
  end

  def self.current_month_period
    @current_month_period ||= Period.current.previous
  end
end
