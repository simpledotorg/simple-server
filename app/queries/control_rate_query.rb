class ControlRateQuery
  attr_reader :patients

  COHORT_DELTA = 9.months

  def initialize(patients:)
    @patients = patients
  end

  def for_period(from_time:, to_time:)
    control_rate_in_period(from_time, to_time)
  end

  def rate_per_month(number_of_months, before_time: Date.today)
    control_rate_per_month = []
    number_of_months.times do |n|
      to_time = (before_time - n.months).at_end_of_month
      from_time = to_time.at_beginning_of_month
      control_rate_per_month << [from_time.to_date, for_period(from_time: from_time, to_time: to_time)[:control_rate] || 0]
    end
    control_rate_per_month.sort.to_h
  end

  private

  def control_rate_in_period(from_time, to_time)
    hypertensive_patients_ids = hypertensive_patients_recorded_in_period(
      from_time - COHORT_DELTA,
      to_time - COHORT_DELTA
    )

    numerator = patients_under_control_in_period(hypertensive_patients_ids, from_time, to_time).size
    denominator = hypertensive_patients_ids.count
    control_rate = (numerator * 100.0 / denominator).round unless denominator == 0

    { control_rate: control_rate,
      hypertensive_patients_in_cohort: denominator,
      patients_under_control_in_period: numerator }
  end

  def hypertensive_patients_recorded_in_period(from_time, to_time)
    BloodPressure.hypertensive
      .where(patient: patients)
      .where("device_created_at >= ?", from_time)
      .where("device_created_at <= ?", to_time)
      .pluck(:patient_id)
      .uniq
  end

  def patients_under_control_in_period(patient_ids, from_time, to_time)
    Patient.where(id: patient_ids)
      .joins(:latest_blood_pressure)
      .where('latest_blood_pressures.systolic <= ?', 140)
      .where('latest_blood_pressures.diastolic <= ?', 90)
      .where(latest_blood_pressures: { device_created_at: from_time..to_time })
  end
end