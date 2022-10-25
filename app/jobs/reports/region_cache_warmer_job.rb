class Reports::RegionCacheWarmerJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :default
  sidekiq_throttle(
    concurrency: { limit: 2 }
  )

  def perform(region_type, limit, offset)
    if Flipper.enabled?(:disable_region_cache_warmer)
      Rails.logger.info "Cache warmer disabled via flipper - exiting"
      return
    end

    Rails.logger.info "Warming repository cache for #{region_type}, limit: #{limit}, offset: #{offset}"
    warm_cache(region_type, limit, offset)
    Rails.logger.info "Finished warming repository cache for #{region_type}, limit: #{limit}, offset: #{offset}"
  end

  def warm_cache(region_type, limit, offset)
    RequestStore.store[:bust_cache] = true
    Time.use_zone(Period::REPORTING_TIME_ZONE) do
      period = Reports.default_period
      regions = Region.where(region_type: region_type).limit(limit).offset(offset)
      range = (period.advance(months: -23)..period)

      Reports::Repository.new(regions, periods: range).warm_cache
    end
  ensure
    RequestStore.store[:bust_cache] = false
  end
end
