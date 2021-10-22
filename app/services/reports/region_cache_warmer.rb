module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def initialize(period: RegionService.default_period)
      @period = period
      notify "starting region reports cache warming"
    end

    attr_reader :period

    def call
      if Flipper.enabled?(:disable_region_cache_warmer)
        notify "disabled via flipper - exiting"
        return
      end

      start_time = Time.current
      Region.where.not(region_type: ["organization", "root"]).each do |region|
        warm_region_cache(region)
      end

      if Flipper.feature(:organization_reports).state.in?([:on, :conditional])
        Region.where(region_type: "organization").each do |region|
          warm_region_cache(region)
        end
      end

      Region::REGION_TYPES.reject { |t| t.in?(["organization", "root"]) }.each do |region_type|
        Region.public_send("#{region_type}_regions").find_in_batches do |batch|
          warm_repository_v2_cache(batch)
        end
      end

      notify "finished region reports cache warming in #{Time.current.to_i - start_time.to_i}s"
    ensure
      RequestStore.store[:bust_cache] = false
    end

    def warm_repository_v2_cache(regions)
      region_type = regions.first.region_type
      notify "Starting V2 region cache for batch of #{region_type} regions"
      range = (period.advance(months: -23)..period)
      Datadog.tracer.trace("region_cache_warmer.warm_repository_v2", resource: region_type) do |span|
        repo = Repository.new(regions, periods: range, reporting_schema_v2: true)
        repo.warm_cache
      end
      Statsd.instance.increment("region_cache_warmer.#{region_type}.repository_v2.cache", regions.count)
    end

    def warm_region_cache(region)
      Time.use_zone(Period::REPORTING_TIME_ZONE) do
        RequestStore.store[:bust_cache] = true

        notify "starting region caching for region #{region.id}"
        Statsd.instance.time("region_cache_warmer.time") do
          Reports::RegionService.call(region: region, period: period)
          Statsd.instance.increment("region_cache_warmer.#{region.region_type}.cache")
          Reports::RepositoryCacheWarmer.call(region: region, period: period)

          PatientBreakdownService.call(region: region, period: period)
          Statsd.instance.increment("patient_breakdown_service.#{region.region_type}.cache")
        end

        notify "finished region caching for region #{region.id}"
      end
    end

    private

    def notify(msg, extra = {})
      data = {
        logger: {
          name: self.class.name
        },
        class: self.class.name
      }.merge(extra).merge(msg: msg)
      Rails.logger.info data
    end
  end
end
