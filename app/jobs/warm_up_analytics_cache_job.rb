class WarmUpAnalyticsCacheJob < ApplicationJob
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

  private

  def perform_facility_group_caching(from_time_string, to_time_string)
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


  def perform_districts_caching(from_time_string, to_time_string)
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
