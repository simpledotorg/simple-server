class PatientsReturningDuringPeriodQuery
  attr_reader :patients, :from_time, :to_time

  def initialize(patients:, from_time:, to_time:)
    @patients = patients
    @from_time = from_time
    @to_time = to_time
  end

  def call
    patients
      .where('patients.recorded_at <= ?', from_time)
      .joins(%Q(
        INNER JOIN (
          SELECT DISTINCT ON (patient_id) *
          FROM blood_pressures
          WHERE recorded_at >= '#{from_time}'
          AND recorded_at <= '#{to_time}'
          ORDER BY patient_id, recorded_at DESC
        ) as newest_bps
        ON newest_bps.patient_id = patients.id
      ))
  end
end
