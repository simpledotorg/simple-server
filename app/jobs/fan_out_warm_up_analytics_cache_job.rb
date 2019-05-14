class FanOutWarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  attr_reader :from_time, :to_time

  def perform
    @to_time = Time.now
    @from_time = to_time - 90.days

    LatestBloodPressure.refresh # This refreshes the materialized view

    FacilityGroup.all.each do |facility_group|
      enqueue_cache_warmup(facility_group)
      facility_group.facilities.each do |facility|
        enqueue_cache_warmup(facility)
      end
    end
  end

  private

  def enqueue_cache_warmup(record)
    WarmUpAnalyticsCacheJob.perform_later(
      record.class.to_s,
      record.id,
      from_time,
      to_time
    )
  end
end