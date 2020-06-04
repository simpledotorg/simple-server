class BloodPressureRollupBackfillJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(patients)
    patients.each do |patient|
      latest_bps = LatestBloodPressuresPerPatientPerMonth.where(patient: patient)
      latest_bps.each do |latest|
        blood_pressure = BloodPressure.find(latest.bp_id)
        blood_pressure.create_or_update_rollup
      end
    end
  end
end
