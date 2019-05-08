class WarmUpAnalyticsCacheJob < ApplicationJob
  queue_as :default
  self.queue_adapter = :sidekiq

  def perform
    to_time = Time.now
    from_time = to_time - 90.days

    perform_facility_group_caching(from_time, to_time)
    perform_districts_caching(from_time, to_time)
  end

  private

  def perform_facility_group_caching(from_time, to_time)
    FacilityGroup.all.each do |facility_group|
      WarmUpFacilityGroupAnalyticsCacheJob.perform_later(
        facility_group,
        from_time.strftime('%Y-%m-%d'),
        to_time.strftime('%Y-%m-%d'))
    end
  end


  def perform_districts_caching(from_time, to_time)
    organizations = Organization.all

    organizations.each do |organization|
      district_facilities_map = organization.facility_groups.flat_map(&:facilities).group_by(&:district)

      district_facilities_map.each do |id, facilities|
        district = District.new(id)
        district.organization_id = organization.id
        district.facilities = facilities

        WarmUpDistrictAnalyticsCacheJob.perform_later(
          district,
          from_time.strftime('%Y-%m-%d'),
          to_time.strftime('%Y-%m-%d'))
      end
    end
  end
end
