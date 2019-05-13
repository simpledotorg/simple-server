class WarmUpQuarterlyAnalyticsCacheJob < ApplicationJob
  include Cacheable
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)
      from_time_string = range[:from_time].strftime('%Y-%m-%d')
      to_time_string = range[:to_time].strftime('%Y-%m-%d')

      perform_facility_group_caching(from_time_string, to_time_string)
      perform_districts_caching(from_time_string, to_time_string)
    end
  end
end

