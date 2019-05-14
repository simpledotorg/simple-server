class PatientsReturningDuringPeriodQuery
  attr_reader :patients, :from_time, :to_time

  def initialize(patients:, from_time:, to_time:)
    @patients = patients
    @from_time = from_time
    @to_time = to_time
  end

  def call
    patients.where(latest_blood_pressures: { device_created_at: from_time..to_time })
  end
end