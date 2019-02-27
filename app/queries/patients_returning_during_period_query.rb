class PatientsReturningDuringPeriodQuery
  attr_reader :patients, :from_time, :to_time

  def initialize(patients:, from_time:, to_time:)
    @patients = patients
    @from_time = from_time
    @to_time = to_time
  end

  def call
    patients
      .where('device_created_at <= ?', from_time)
      .includes(:latest_blood_pressures)
      .select do |patient|
      latest_blood_pressure = patient.latest_blood_pressure
      (latest_blood_pressure.present? && latest_blood_pressure.device_created_at >= from_time && latest_blood_pressure.device_created_at < to_time)
    end
  end
end