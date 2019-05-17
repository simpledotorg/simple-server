class WarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform(record_type, record_id, from_time_string, to_time_string)
    record = record_type.constantize.find(record_id)
    record.patient_set_analytics(from_time_string.to_time, to_time_string.to_time)
  end
end
