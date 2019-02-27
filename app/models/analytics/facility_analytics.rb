class Analytics::FacilityAnalytics
  attr_reader :facility, :from_time, :to_time

  def initialize(facility, from_time: Time.new(0), to_time: Time.now, months_previous: 12)
    @facility = facility
    @from_time = from_time
    @to_time = to_time
    @months_previous = months_previous
  end

  def fetch_from_cache
    Rails.cache.fetch(cache_key) do
      { blood_pressures_recorded_per_week: blood_pressures_recorded_per_week,
        unique_patients_enrolled: unique_patients_enrolled.count,
        newly_enrolled_patients: newly_enrolled_patients.count,
        newly_enrolled_patients_per_month: newly_enrolled_patients_per_month,
        returning_patients: returning_patients.count,
        non_returning_hypertensive_patients: non_returning_hypertensive_patients.count,
        non_returning_hypertensive_patients_per_month: non_returning_hypertensive_patients_per_month(4),
        control_rate: control_rate,
        control_rate_per_month: control_rate_per_month(4),
        all_time_patients_count: all_time_patients_count,
        unique_patients_recorded_per_month: unique_patients_recorded_per_month
      }
    end
  end

  def unique_patients_enrolled
    UniquePatientsEnrolledQuery.new(facilities: facility).call
  end

  def newly_enrolled_patients
    NewlyEnrolledPatientsQuery.new(facilities: facility, from_time: from_time, to_time: to_time).call
  end

  def newly_enrolled_patients_per_month
    Patient.where(registration_facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .count(:id)
  end

  def returning_patients
    PatientsReturningDuringPeriodQuery.new(
      facilities: facility,
      from_time: from_time,
      to_time: to_time
    ).call
  end

  def non_returning_hypertensive_patients
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility
    ).non_returning_since(to_time)
  end

  def non_returning_hypertensive_patients_per_month(number_of_months)
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      facilities: facility
    ).count_per_month(number_of_months, before_time: to_time)
  end

  def control_rate
    ControlRateQuery.new(facilities: facility).for_period(from_time: from_time, to_time: to_time)
  end

  def control_rate_per_month(number_of_months)
    ControlRateQuery.new(facilities: facility)
      .rate_per_month(number_of_months)
  end

  def all_time_patients_count
    Patient.where(registration_facility: facility).count
  end

  def blood_pressures_recorded_per_week
    facility.blood_pressures
      .where.not(user: nil)
      .group_by_week(:device_created_at, last: 12)
      .count
  end

  def unique_patients_recorded_per_month
    BloodPressure.where(facility: facility)
      .group_by_month(:device_created_at, last: @months_previous)
      .distinct
      .count(:patient_id)
  end

  private

  def cache_key
    "analytics/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{facility.cache_key}"
  end

  def time_cache_key(time)
    time.strftime('%Y-%m-%d')
  end
end
