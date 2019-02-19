class ControlRateQuery
  attr_reader :facilities, :from_time, :to_time

  COHORT_DELTA = 9.months

  def initialize(facilities:, from_time:, to_time:)
    @facilities = facilities
    @from_time = from_time
    @to_time = to_time
  end

  def call
    hypertensive_patients_ids = hypertensive_patients_recorded_in_period(
      from_time - COHORT_DELTA,
      to_time - COHORT_DELTA
    )

    numerator = patients_under_control_in_period(hypertensive_patients_ids).size
    denominator = hypertensive_patients_ids.count

    (numerator * 100.0 / denominator).round unless denominator == 0
  end

  private

  def hypertensive_patients_recorded_in_period(from_time, to_time)
    BloodPressure.hypertensive
      .where(facility: facilities)
      .where("device_created_at >= ?", from_time)
      .where("device_created_at <= ?", to_time)
      .pluck(:patient_id)
      .uniq
  end

  def patients_under_control_in_period(patient_ids)
    Patient.where(id: patient_ids)
      .includes(:latest_blood_pressures)
      .select { |patient| patient_under_control_in_period?(patient) }
  end

  def patient_under_control_in_period?(patient)
    latest_blood_pressure = patient.latest_blood_pressure
    (latest_blood_pressure.present? &&
      latest_blood_pressure.under_control? &&
      latest_blood_pressure.device_created_at >= from_time &&
      latest_blood_pressure.device_created_at < to_time)
  end
end