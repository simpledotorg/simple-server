class WarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :default

  def perform
    to_time = Time.now
    from_time = to_time - 90.days
    FacilityGroup.all.each do |facility_group|
      WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
        facility_group,
        from_time.strftime('%Y-%m-%d'),
        to_time.strftime('%Y-%m-%d'))
    end
  end
end