module Cacheable
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