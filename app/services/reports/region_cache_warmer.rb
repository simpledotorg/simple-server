module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    BATCH_SIZE = 1000

    def initialize(period: RegionService.default_period)
      @period = period
      @original_force_cache = RequestStore.store[:force_cache]
      RequestStore.store[:force_cache] = true
      notify "start"
    end

    attr_reader :original_force_cache
    attr_reader :period
    attr_reader :notifier

    def call
      duration = Benchmark.ms {
        if Flipper.enabled?(:disable_region_cache_warmer)
          notify "disabled via flipper - exiting"
          return
        end

        notify "starting region caching"
        Statsd.instance.time("region_cache_warmer.states") do
          Region.where.not(region_type: ["root", "organization"]).find_each(batch_size: BATCH_SIZE) do |region|
            RegionService.call(region: region, period: period)
            Statsd.instance.increment("region_cache_warmer.states.cache")
          end
        end

      }
      notify "finished", duration: duration
    ensure
      RequestStore.store[:force_cache] = original_force_cache
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
