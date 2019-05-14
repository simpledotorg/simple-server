class PatientsReturningDuringPeriodQuery
  attr_reader :patients, :from_time, :to_time

  def initialize(patients:, from_time:, to_time:)
    @patients = patients
    @from_time = from_time
    @to_time = to_time
  end

  def call
    patients
      .joins(:cached_latest_blood_pressure)
      .where('patients.device_created_at <= ?', from_time)
      .where(cached_latest_blood_pressures: { device_created_at: from_time..to_time })
  end
end