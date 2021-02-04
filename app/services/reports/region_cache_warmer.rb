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

        notify "starting state caching"
        Statsd.instance.time("region_cache_warmer.states") do
          cache_states
        end
        Statsd.instance.time("region_cache_warmer.with_exclusions.states") do
          cache_states(with_exclusions: true)
        end

        notify "starting facility_group caching"
        Statsd.instance.time("region_cache_warmer.facility_groups") do
          cache_facility_groups
        end
        Statsd.instance.time("region_cache_warmer.with_exclusions.facility_groups") do
          cache_facility_groups(with_exclusions: true)
        end

        notify "starting block caching"
        Statsd.instance.time("region_cache_warmer.blocks") do
          cache_blocks
        end
        Statsd.instance.time("region_cache_warmer.with_exclusions.blocks") do
          cache_blocks(with_exclusions: true)
        end

        notify "starting facility caching"
        Statsd.instance.time("region_cache_warmer.facilities") do
          cache_facilities
        end
        Statsd.instance.time("region_cache_warmer.with_exclusions.facilities") do
          cache_facilities(with_exclusions: true)
        end
      }
      notify "finished", duration: duration
    ensure
      RequestStore.store[:force_cache] = original_force_cache
    end

    private

    def cache_states(with_exclusions: false)
      Region.state_regions.each do |region|
        RegionService.call(region: region, period: period, with_exclusions: with_exclusions)
        Statsd.instance.increment("region_cache_warmer.states.cache")
      end
    end

    def cache_facility_groups(with_exclusions: false)
      FacilityGroup.find_each(batch_size: BATCH_SIZE).each do |region|
        RegionService.call(region: region, period: period, with_exclusions: with_exclusions)
        Statsd.instance.increment("region_cache_warmer.facility_groups.cache")
      end
    end

    def cache_blocks(with_exclusions: false)
      Region.block_regions.find_each(batch_size: BATCH_SIZE).each do |region|
        RegionService.call(region: region, period: period, with_exclusions: with_exclusions)
        Statsd.instance.increment("region_cache_warmer.blocks.cache")
      end
    end

    def cache_facilities(with_exclusions: false)
      Facility.find_each(batch_size: BATCH_SIZE).each do |region|
        RegionService.call(region: region, period: period, with_exclusions: with_exclusions)
        Statsd.instance.increment("region_cache_warmer.facilities.cache")
      end
    end

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
