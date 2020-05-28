class BloodPressureRollupBackfill < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(patients)
    patients.each do |patient|
      latest_bps = LatestBloodPressuresPerPatientPerMonth.where(patient: patient)
      latest_bps.each do |latest|
        blood_pressure = BloodPressure.find(latest.bp_id)
        BloodPressureRollup.from_blood_pressure blood_pressure
      end
    end
  end
end
