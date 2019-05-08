class WarmUpFacilityAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(facility, from_time, to_time)
    facility.patient_set_analytics(from_time, to_time)
  end
end