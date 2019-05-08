class District
  extend ActiveModel::Naming
  include PatientSetAnalyticsReportable

  attr_reader :id
  attr_accessor :facilities, :organization_id, :state

  def initialize(id)
    @id = id
  end

  def to_model
  end

  def persisted?
    false
  end

  def cache_key
    facilities_ids_string = @facilities.map(&:id).sort.join
    Digest::SHA512.base64digest(facilities_ids_string)
  end

  def report_on_patients
    facilities_ids = @facilities.map(&:id)
    Patient.where(registration_facility: facilities_ids)
  end

  def analytics_cache_key(from_time, to_time)
    organization = Organization.find(@organization_id)
    "analytics/organization/#{organization.id}/district/#{@id}/#{time_cache_key(from_time)}/#{time_cache_key(to_time)}/#{cache_key}"
  end
end