class WarmUpDistrictAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(district, from_time_string, to_time_string)
    puts "Processing #{district.id}"
    from_time = from_time_string.to_time
    to_time = to_time_string.to_time
    district.patient_set_analytics(from_time, to_time)
    district.facilities.each do |facility|
      WarmUpFacilityAnalyticsCacheJob.perform_now(
        facility, from_time, to_time)
    end
    puts "Finished processing #{district.id}"
  end
end