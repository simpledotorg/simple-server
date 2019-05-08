class WarmUpQuarterlyAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

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

  private

  def perform_districts_caching(from_time, to_time)
    organizations = Organization.all

    organizations.each do |organization|
      puts "Processing organization #{organization.name}"
      district_facilities_map = organization.facility_groups.flat_map(&:facilities).group_by(&:district)

      district_facilities_map.each do |id, facilities|
        district = District.new(id)
        district.organization_id = organization.id
        district.facilities = facilities

        WarmUpDistrictAnalyticsCacheJob.perform_now(
          district,
          from_time.strftime('%Y-%m-%d'),
          to_time.strftime('%Y-%m-%d'))
      end
      puts "Finished processing organization #{organization.name}"
    end
  end
end
