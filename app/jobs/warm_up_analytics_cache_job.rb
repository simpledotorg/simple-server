class WarmUpAnalyticsCacheJob < ApplicationJob
  include AnalyticsCacheable
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    to_time = Time.now
    from_time = to_time - 90.days

    from_time_string = from_time.strftime('%Y-%m-%d')
    to_time_string = to_time.strftime('%Y-%m-%d')

    perform_facility_group_caching(from_time_string, to_time_string)
    perform_districts_caching(from_time_string, to_time_string)
  end
end
