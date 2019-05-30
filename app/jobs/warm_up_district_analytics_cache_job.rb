class WarmUpDistrictAnalyticsCacheJob < ApplicationJob
  queue_as :analytics_warmup
  self.queue_adapter = :sidekiq

  def perform(district_name, organization_id, from_time_string, to_time_string)
    organization_district = OrganizationDistrict.new(district_name, Organization.find(organization_id))
    from_time = from_time_string.to_time
    to_time = to_time_string.to_time

    Rails.cache.delete(organization_district.analytics_cache_key(from_time, to_time))
    organization_district.patient_set_analytics(from_time, to_time)
  end
end