class NonReturningHypertensivePatientsDuringPeriodQuery
  attr_reader :facilities, :before_time

  def initialize(facilities:, before_time:)
    @facilities = facilities
    @before_time = before_time
  end

  def call
    Patient.where(registration_facility: facilities)
      .includes(:latest_blood_pressures)
      .select { |patient| non_returning_patient? patient }
  end

  private

  def non_returning_patient?(patient)
    latest_blood_pressure = patient.latest_blood_pressure

    latest_blood_pressure.present? &&
      latest_blood_pressure.hypertensive? &&
      latest_blood_pressure.device_created_at < before_time
  end

end