class Analytics::PatientSetAnalytics
  attr_reader :patients, :from_time, :to_time

  def initialize(patients, from_time, to_time)
    @patients = patients.includes(:latest_blood_pressures)
    @from_time = from_time
    @to_time = to_time
  end

  def unique_patients_count
    patients.distinct.count
  end

  def unique_patients_count_per_month(months_previous)
    patients
      .group_by_month(:device_created_at, last: months_previous)
      .distinct
      .count
  end

  def newly_enrolled_patients_count
    patients.where(device_created_at: from_time..to_time).count
  end

  def newly_enrolled_patients_count_per_month(months_previous)
    patients
      .group_by_month(:device_created_at, last: months_previous)
      .count
  end

  def returning_patients_count
    PatientsReturningDuringPeriodQuery.new(
      patients: patients,
      from_time: from_time,
      to_time: to_time
    ).call.count
  end

  def non_returning_hypertensive_patients_count
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      patients: patients
    ).non_returning_since(from_time).count
  end

  def non_returning_hypertensive_patients_count_per_month(months_previous)
    NonReturningHypertensivePatientsDuringPeriodQuery.new(
      patients: patients
    ).count_per_month(months_previous, before_time: to_time)
  end

  def control_rate
    ControlRateQuery.new(patients: patients).for_period(from_time: from_time, to_time: to_time)
  end

  def control_rate_per_month(months_previous)
    ControlRateQuery.new(patients: patients).rate_per_month(months_previous)
  end

  def blood_pressures_recorded_per_week(weeks_previous)
    BloodPressure.where(patient: patients)
      .group_by_week(:device_created_at, last: weeks_previous)
      .count
  end
end