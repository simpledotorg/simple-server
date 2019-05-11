class WarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    to_time = Time.now
    from_time = to_time - 90.days

    from_time_string = from_time.strftime('%Y-%m-%d')
    to_time_string = to_time.strftime('%Y-%m-%d')

    ApplicationController.helpers.perform_facility_group_caching(from_time_string, to_time_string)
    ApplicationController.helpers.perform_districts_caching(from_time_string, to_time_string)
  end
end
