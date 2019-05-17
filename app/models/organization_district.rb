class OrganizationDistrict < Struct.new(:district_name, :organization)
  include PatientSetAnalyticsReportable

  def organization_district_id
    id_string = organization.id + district_name
    Digest::SHA512.base64digest(id_string)
  end

  def report_on_patients
    Patient.where(registration_facility: facilities)
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def facilities
    organization.facilities.where(district: district_name)
  end

  def cache_key
    facilities_ids_string = facilities.map(&:id).sort.join
    Digest::SHA512.base64digest(facilities_ids_string)
  end

  def analytics_cache_key(from_time, to_time)
    "analytics/organization/#{organization.id}/district/#{district_slug(district_name)}/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{cache_key}"
  end

  def district_slug(district_name)
    district_name.split(" ").select(&:present?).join("-").downcase
  end
end