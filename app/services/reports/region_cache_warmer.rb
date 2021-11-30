module Reports
  class RegionCacheWarmer
    prepend SentryHandler

    def self.call
      new.call
    end

    attr_reader :name
    attr_reader :period

    def initialize(period: Reports.default_period)
      @period = period
      @name = self.class.name.to_s
      notify "Starting #{name} warming"
    end

    def call
      if Flipper.enabled?(:disable_region_cache_warmer)
        notify "disabled via flipper - exiting"
        return
      end
      RequestStore.store[:bust_cache] = true

      warm_caches

      notify "Finished all caching for #{name}"
    ensure
      RequestStore.store[:bust_cache] = false
    end

    private

    def warm_caches
      Time.use_zone(Period::REPORTING_TIME_ZONE) do
        Region::REGION_TYPES.reject { |t| t == "root" }.each do |region_type|
          Datadog.tracer.trace("region_cache_warmer.warm_repository_cache", resource: region_type) do |span|
            Region.public_send("#{region_type}_regions").find_in_batches do |batch|
              warm_patient_breakdown_caches(batch)
              warm_repository_caches(batch)
            end
            Statsd.instance.flush
          end
        end
      end
    end

    def warm_repository_caches(regions)
      region_type = regions.first.region_type
      notify "Starting warming cache for repository cache for batch of #{region_type} regions"
      range = (period.advance(months: -23)..period)
      repo = Repository.new(regions, periods: range, reporting_schema_v2: true)
      repo.warm_cache
      Statsd.instance.increment("region_cache_warmer.#{region_type}.warm_repository_cache.region_count", regions.count)
    end

    def warm_patient_breakdown_caches(batch)
      batch.each do |region|
        Statsd.instance.time("region_cache_warmer.patient_breakdown_service.time") do
          PatientBreakdownService.call(region: region, period: period)
          Statsd.instance.increment("patient_breakdown_service.#{region.region_type}.cache")
        end
      end
    end

    private

    def notify(msg, extra = {})
      data = {
        logger: {
          name: name
        },
        class: name,
        module: "reports"
      }.merge(extra).merge(msg: msg)
      Rails.logger.info data
    end
  end
end
