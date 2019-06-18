class OrganizationDistrict < Struct.new(:district_name, :organization)
  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end

  def analytics_by_facility
    analytics = DistrictAnalyticsQuery.new(district_name: district_name)

    {
      total_registered_patients: analytics.registered_patients_by_month.map { |k, v| [k, v.values.sum] }.to_h,
      registered_patients: analytics.registered_patients_by_month,
      follow_up_patients_by_month: analytics.follow_up_patients_by_month
    }
  end
end
