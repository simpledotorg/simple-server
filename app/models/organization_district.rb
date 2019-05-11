class OrganizationDistrict < Struct.new(:district_name, :organization, :facilities)
  include PatientSetAnalyticsReportable

  def organization_district_id
    id_string = organization.id + district_name
    Digest::SHA512.base64digest(id_string)
  end

  def report_on_patients
    Patient.where(registration_facility: @facilities)
  end

  def cache_key
    facilities_ids_string = facilities.map(&:id).sort.join
    Digest::SHA512.base64digest(facilities_ids_string)
  end

  def analytics_cache_key(from_time, to_time)
    "analytics/organization/#{organization.id}/district/#{district_name}/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{cache_key}"
  end
end