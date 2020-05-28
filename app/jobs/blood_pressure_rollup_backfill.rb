class BloodPressureRollupBackfill < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(patients)
    patients.find_each do |patient|
      bps = patient.blood_pressures.group_by(:month, :recorded_at)
    end
  end
end
