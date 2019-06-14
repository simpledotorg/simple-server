class OrganizationDistrict < Struct.new(:district_name, :organization)
  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def analytics_by_facility
    DistrictAnalyticsQuery
      .new(district_name: district_name)
      .by_facility
  end
end
