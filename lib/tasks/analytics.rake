def enqueue_cache_warmup(record, from_time, to_time)
  record_class = record.class.to_s
  WarmUpAnalyticsCacheJob.perform_later(
    record_class,
    record.id,
    from_time,
    to_time
  )
  Rails.logger.info("Enqueued job to warm up for #{record_class} - #{record.id}")
end

def warmup_analytics_for_organization_districts(from_time_string, to_time_string)
  Organization.all.each do |organization|
    organization.districts.each do |district_name|
      WarmUpDistrictAnalyticsCacheJob.perform_later(
        district_name,
        organization.id,
        from_time_string,
        to_time_string)
      Rails.logger.info("Enqueued job to warm up for organization district (#{organization.name}, #{district_name})")
    end
  end
end

def warmup_analytics_for_facility_groups(from_time_string, to_time_string)
  FacilityGroup.all.each do |facility_group|
    enqueue_cache_warmup(facility_group, from_time_string, to_time_string)
  end
end

def warmup_analytics_for_facilities(from_time_string, to_time_string)
  Facility.all.each do |facility|
    enqueue_cache_warmup(facility, from_time_string, to_time_string)
  end
end


namespace :analytics do
  desc 'Warm up analytics for last 90 days'
  task warm_up_last_ninety_days: :environment do
    Rails.logger = Logger.new(STDOUT)
    timezone = ENV.fetch('ANALYTICS_TIME_ZONE')

    to_time = Time.now.in_time_zone(timezone)
    from_time = (to_time - 90.days).in_time_zone(timezone)

    from_time_string = from_time.strftime('%Y-%m-%d')
    to_time_string = to_time.strftime('%Y-%m-%d')

    warmup_analytics_for_facilities(from_time_string, to_time_string)
    warmup_analytics_for_facility_groups(from_time_string, to_time_string)
    warmup_analytics_for_organization_districts(from_time_string, to_time_string)
  end

  desc 'Warm up analytics for last four quarters'
  task warm_up_last_four_quarters: :environment do
    Rails.logger = Logger.new(STDOUT)
    timezone = ENV.fetch('ANALYTICS_TIME_ZONE')

    (1..4).each do |n|
      range = ApplicationController.helpers.range_for_quarter(-1 * n)
      from_time_string = range[:from_time].in_time_zone(timezone).strftime('%Y-%m-%d')
      to_time_string = range[:to_time].in_time_zone(timezone).strftime('%Y-%m-%d')

      warmup_analytics_for_facilities(from_time_string, to_time_string)
      warmup_analytics_for_facility_groups(from_time_string, to_time_string)
      warmup_analytics_for_organization_districts(from_time_string, to_time_string)
    end
  end
end
