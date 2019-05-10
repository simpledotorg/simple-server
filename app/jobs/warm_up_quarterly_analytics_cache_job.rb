class WarmUpQuarterlyAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)
      from_time_string = range[:from_time].strftime('%Y-%m-%d')
      to_time_string = range[:to_time].strftime('%Y-%m-%d')

      perform_caching_for_facility_group(from_time_string, to_time_string)
      perform_caching_for_districts(from_time_string, to_time_string)
    end
  end

  private

  def perform_caching_for_facility_group(from_time_string, to_time_string)
    FacilityGroup.all.each do |facility_group|
      WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
        facility_group,
        from_time_string,
        to_time_string)

      facility_group.facilities.each do |facility|
        WarmUpFacilityAnalyticsCacheJob.perform_later(
          facility, from_time_string, to_time_string)
      end
    end
  end

  def perform_caching_for_districts(from_time_string, to_time_string)
    Organization.all.each do |organization|
      district_facilities_map = organization.facilities.group_by(&:district)

      district_facilities_map.each do |name, facilities|
        district = OrganizationDistrict.new(name, organization, facilities)

        WarmUpDistrictAnalyticsCacheJob.perform_later(
          district,
          from_time_string,
          to_time_string)

        district.facilities.each do |facility|
          WarmUpFacilityAnalyticsCacheJob.perform_later(
            facility, from_time_string, to_time_string)
        end
      end
    end
  end
end

