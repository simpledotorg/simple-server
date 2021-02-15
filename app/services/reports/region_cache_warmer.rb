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
        Statsd.instance.time("region_cache_warmer") do
          Region.where.not(region_type: ["root", "organization"]).pluck(:id).each do |region_id|
            RegionCacheWarmerJob.perform_async(region_id, period.attributes)
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
