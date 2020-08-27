module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def initialize(period: RegionService.default_period)
      @notifier = Slack::Notifier.new(ENV["SLACK_ALERTS_WEBHOOK_URL"], channel: "#alerts", username: "simple-server")
      @start_time = Time.current
      @period = period
      @original_force_cache = RequestStore.store[:force_cache]
      RequestStore.store[:force_cache] = true
      notifier.ping "#{self.class.name} Starting ..."
    end

    attr_reader :original_force_cache, :period
    attr_reader :start_time
    attr_reader :notifier

    delegate :logger, to: Rails

    def call
      if Flipper.enabled?(:disable_region_cache_warmer)
        notifier.ping "#{self.class.name} is disabled via Flipper! Bailing out early"
        return
      end

      notifier.ping "Starting FacilityGroup caching"
      time = Benchmark.realtime {
        cache_facility_groups
      }
      notifier.ping "Finished FacilityGroups caching in #{time.round} seconds."

      notifier.ping "Starting Facility caching."
      time = Benchmark.realtime {
        cache_facilities
      }
      end_time = Time.current
      total_time = end_time - start_time
      notifier.ping "Finished Facility caching in #{time.round} seconds, total cache time was #{total_time.round} seconds."
      notifier.ping "#{self.class.name} All done!"
    ensure
      RequestStore.store[:force_cache] = original_force_cache
    end

    private

    def cache_facility_groups
      FacilityGroup.all.each do |region|
        logger.info { "class=#{self.class.name} region=#{region.name}" }
        RegionService.new(region: region, period: period).call
      end
    end

    def cache_facilities
      Facility.all.each do |region|
        logger.info { "class=#{self.class.name} region=#{region.name}" }
        RegionService.new(region: region, period: period).call
      end
    end

  end
end
