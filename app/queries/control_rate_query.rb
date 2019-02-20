class ControlRateQuery
  attr_reader :facilities

  COHORT_DELTA = 9.months

  def initialize(facilities:)
    @facilities = facilities
  end

  def for_period(from_time:, to_time:)
    control_rate_in_period(from_time, to_time)
  end

  def rate_per_month(number_of_months)
    control_rate_per_month = {}
    number_of_months.times do |n|
      from_time = (number_of_months - n).months.ago.at_beginning_of_month
      to_time = (number_of_months - n).months.ago.at_end_of_month
      control_rate_per_month[from_time] = for_period(from_time: from_time, to_time: to_time)[:control_rate] || 0
    end
    control_rate_per_month
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
      .where(facility: facilities)
      .where("device_created_at >= ?", from_time)
      .where("device_created_at <= ?", to_time)
      .pluck(:patient_id)
      .uniq
  end

  def patients_under_control_in_period(patient_ids, from_time, to_time)
    Patient.where(id: patient_ids)
      .includes(:latest_blood_pressures)
      .select { |patient| patient_under_control_in_period?(patient, from_time, to_time) }
  end

  def patient_under_control_in_period?(patient, from_time, to_time)
    latest_blood_pressure = patient.latest_blood_pressure
    (latest_blood_pressure.present? &&
      latest_blood_pressure.under_control? &&
      latest_blood_pressure.device_created_at >= from_time &&
      latest_blood_pressure.device_created_at < to_time)
  end
end