class District
  extend ActiveModel::Naming
  include PatientSetAnalyticsReportable

  attr_reader :id, :organization
  attr_accessor :facilities_ids

  def initialize(id, organization)
    @id = id
    @organization = organization
  end

  def to_model
  end

  def persisted?
    false
  end

  def cache_key
    facilities_ids_string = @facilities_ids.sort.join
    Digest::SHA512.base64digest(facilities_ids_string)
  end

  def report_on_patients
    Patient.where(registration_facility: @facilities_ids)
  end

  def analytics_cache_key(from_time, to_time)
    "analytics/organization/#{@organization.id}/district/#{@id}/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{cache_key}"
  end
end