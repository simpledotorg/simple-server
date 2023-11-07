module Dhis2::Helpers
  def self.previous_month_period
    @previous_month_period ||= Period.current.previous
  end

  def self.last_n_month_periods(n)
    (previous_month_period.advance(months: -n + 1)..previous_month_period)
  end

  def self.htn_controlled(region, period)
    PatientStates::Hypertension::ControlledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_assigned(region, period)
    PatientStates::Hypertension::CumulativeAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_assigned_adjusted(region, period)
    PatientStates::Hypertension::AdjustedAssignedPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_cumulative_registrations(region, period)
    PatientStates::Hypertension::CumulativeRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_dead(region, period)
    PatientStates::Hypertension::DeadPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_monthly_registrations(region, period)
    PatientStates::Hypertension::MonthlyRegistrationsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_ltfu(region, period)
    PatientStates::Hypertension::LostToFollowUpPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_missed_visits(region, period)
    PatientStates::Hypertension::MissedVisitsPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.htn_uncontrolled(region, period)
    PatientStates::Hypertension::UncontrolledPatientsQuery
      .new(region, period)
      .call
      .count
  end

  def self.disaggregate_by_gender_age(patient_states, buckets)
    gender_age_counts(patient_states, buckets).transform_keys do |(gender, age_bucket_index)|
      gender_age_range_key(gender, buckets, age_bucket_index)
    end
  end

  def self.gender_age_counts(patient_states, buckets)
    PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_age(
      buckets,
      PatientStates::DisaggregatedPatientCountQuery.disaggregate_by_gender(patient_states)
    ).count
  end

  def self.gender_age_range_key(gender, buckets, age_bucket_index)
    age_range_start = buckets[age_bucket_index - 1]
    if age_range_start == buckets.last
      "#{gender}_#{age_range_start}_plus"
    else
      age_range_end = buckets[age_bucket_index] - 1
      "#{gender}_#{age_range_start}_#{age_range_end}"
    end
  end
end
