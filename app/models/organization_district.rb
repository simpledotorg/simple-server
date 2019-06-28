class OrganizationDistrict < Struct.new(:district_name, :organization)
  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def dashboard_analytics
    query = DistrictAnalyticsQuery.new(district_name)
    results = [
      query.registered_patients_by_month,
      query.total_registered_patients,
      query.follow_up_patients_by_month
    ].compact

    return {} if results.blank?
    results.inject(&:deep_merge)
  end
end
