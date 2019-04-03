class WarmUpQuarterlyAnalyticsCacheJob < ApplicationJob
  queue_as :default

  def perform
    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)
      FacilityGroup.all.each do |facility_group|
        WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
          facility_group,
          range[:from_time].strftime('%Y-%m-%d'),
          range[:to_time].strftime('%Y-%m-%d'))
      end
    end
  end
end