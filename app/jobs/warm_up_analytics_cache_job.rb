class WarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :analytics_warmup
  self.queue_adapter = :sidekiq

  def perform(record_type, record_id, from_time_string, to_time_string)
    record = record_type.constantize.find(record_id)

    from_time = from_time_string.to_time
    to_time = from_time_string.to_time

    Rails.cache.delete(record.analytics_cache_key(from_time, to_time))
    record.patient_set_analytics(from_time, to_time)
  end
end
