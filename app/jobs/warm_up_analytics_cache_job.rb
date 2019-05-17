class WarmUpAnalyticsCacheJob < ApplicationJob
  include AnalyticsCacheable
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(record_type, record_id, from_time_string, to_time_string)
    record = record_type.constantize.find(record_id)
    perform_districts_caching(from_time_string, to_time_string)
  end
end

