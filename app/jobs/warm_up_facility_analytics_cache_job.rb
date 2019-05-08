class WarmUpFacilityAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(facility, from_time_string, to_time_string)
    from_time = from_time_string.to_time
    to_time = to_time_string.to_time
    facility.patient_set_analytics(from_time, to_time)
  end
end