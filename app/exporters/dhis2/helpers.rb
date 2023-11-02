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
end
