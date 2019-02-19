class PatientsReturningDuringPeriodQuery
  attr_reader :facilities, :from_time, :to_time

  def initialize(facilities:, from_time:, to_time:)
    @facilities = facilities
    @from_time = from_time
    @to_time = to_time
  end

  def call
    Patient.where(registration_facility: facilities)
      .where('device_created_at <= ?', from_time)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? && latest_blood_pressure.device_created_at >= from_time && latest_blood_pressure.device_created_at < to_time)
    end
  end
end