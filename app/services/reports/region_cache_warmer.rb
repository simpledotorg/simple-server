module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def initialize(period: Reports.default_period)
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

      notify "finished region reports cache warming in #{Time.current.to_i - start_time.to_i}s"
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
