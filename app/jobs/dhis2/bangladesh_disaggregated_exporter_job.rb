class Dhis2::BangladeshDisaggregatedExporterJob
  include Sidekiq::Job
  sidekiq_options retry: 2
  sidekiq_options queue: :default

  STEP = 5
  BUCKETS = (15..75).step(STEP).to_a

  def perform(facility_identifier_id, total_months)
    facility_identifier = FacilityBusinessIdentifier.find(facility_identifier_id)
    periods = Dhis2::Helpers.last_n_month_periods(total_months)
    dhis2_exporter = Dhis2Exporter.new(
      facility_identifiers: [],
      periods: [],
      data_elements_map: config.fetch(:data_elements_map),
      category_option_combo_ids: config.fetch(:category_option_combo_ids)
    )
    export_data = []
    periods.each do |period|
      facility_data_for_period = facility_data_for_period(facility_identifier, period)
      export_data << dhis2_exporter.format_disaggregated_facility_period_data(
        facility_data_for_period,
        facility_identifier,
        period
      )
    end
    dhis2_exporter.send_data_to_dhis2(export_data)
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
    }.transform_values { |patient_states| disaggregate_by_gender_age(patient_states) }
  end

  def disaggregate_by_gender_age(patient_states)
    gender_age_counts(patient_states).transform_keys do |(gender, age_bucket_index)|
      gender_age_range_key(gender, age_bucket_index)
    end
  end

  def gender_age_counts(patient_states)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      BUCKETS,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(patient_states)
    ).count
  end

  def gender_age_range_key(gender, age_bucket_index)
    age_range_start = BUCKETS[age_bucket_index - 1]
    if age_range_start == BUCKETS.last
      "#{gender}_#{age_range_start}_plus"
    else
      age_range_end = BUCKETS[age_bucket_index] - 1
      "#{gender}_#{age_range_start}_#{age_range_end}"
    end
  end

  def config
    {
      data_elements_map: CountryConfig.dhis2_data_elements.fetch(:disaggregated_dhis2_data_elements),
      category_option_combo_ids: CountryConfig.dhis2_data_elements.fetch(:dhis2_category_option_combo)
    }
  end
end
