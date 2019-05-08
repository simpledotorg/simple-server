class WarmUpFacilityAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(facility, from_time, to_time)
    puts "Processing facility #{facility.name}"
    facility.patient_set_analytics(from_time, to_time)
    puts "Finished processing facility #{facility.name}"
  end
end