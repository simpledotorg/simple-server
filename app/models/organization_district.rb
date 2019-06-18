class OrganizationDistrict < Struct.new(:district_name, :organization)
  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def analytics_by_facility
    analytics = DistrictAnalyticsQuery.new(district_name: district_name)

    analytics.follow_up_patients_by_month
      .deep_merge(analytics.registered_patients_by_month)
      .map { |facility_id, analytics| add_total_registered_patients_to_facility_analytics(facility_id, analytics) }
      .inject(&:merge)
  end

  private

  def add_total_registered_patients_to_facility_analytics(facility_id, analytics)
    registered_patients_by_month = analytics[:registered_patients_by_month]
    return { facility_id => analytics.merge(total_registered_patients: 0) } unless registered_patients_by_month.present?

    { facility_id => analytics.merge(total_registered_patients: registered_patients_by_month.values.sum) }
  end
end
