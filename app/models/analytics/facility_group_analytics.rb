class Analytics::FacilityGroupAnalytics
  attr_reader :facility_group, :days_previous, :months_previous, :from_time, :to_time

  def initialize(facility_group, from_time: Time.new(0), to_time: Time.now, days_previous: 7, months_previous: 12)
    @facility_group = facility_group
    @days_previous = days_previous
    @months_previous = months_previous
    @from_time = from_time
    @to_time = to_time
  end

  def fetch_from_cache
    Rails.cache.fetch(cache_key) do
      { blood_pressures_recorded_per_week: blood_pressures_recorded_per_week,
        unique_patients_enrolled: unique_patients_enrolled.count,
        newly_enrolled_patients: newly_enrolled_patients.count,
        returning_patients: returning_patients.count,
        non_returning_hypertensive_patients: non_returning_hypertensive_patients.count,
        non_returning_hypertensive_patients_per_month: non_returning_hypertensive_patients_per_month(4),
        control_rate: control_rate,
        control_rate_per_month: control_rate_per_month(4)
      }
    end
  end

  def blood_pressures_recorded_per_week
    BloodPressure.where(facility: facility_group.facilities)
      .group_by_week(:device_created_at, last: 12)
      .count
  end

  def unique_patients_enrolled
    UniquePatientsEnrolledQuery.new(facilities: facility_group.facilities).call
  end

  def newly_enrolled_patients
    NewlyEnrolledPatientsQuery.new(
      facilities: facility_group.facilities,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def returning_patients
    PatientsReturningDuringPeriodQuery.new(
      facilities: facility_group.facilities,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def non_returning_hypertensive_patients
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility_group.facilities
    ).non_returning_since(from_time)
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility_group.facilities
    ).count_per_month(number_of_months, before_time: to_time)
  end

  def control_rate
    ControlRateQuery.new(facilities: facility_group.facilities)
      .for_period(from_time: from_time, to_time: to_time)
  end

  def control_rate_per_month(number_of_months)
    ControlRateQuery.new(facilities: facility_group.facilities)
      .rate_per_month(number_of_months)
  end

  private

  def cache_key
    "analytics/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{facility_group.cache_key}"
  end

  def time_cache_key(time)
    time.strftime('%Y-%m-%d')
  end
end