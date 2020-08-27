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
      notify "#{self.class.name} Starting ..."
    end

    attr_reader :original_force_cache, :period
    attr_reader :start_time
    attr_reader :notifier

    delegate :logger, to: Rails

    def call
      if Flipper.enabled?(:disable_region_cache_warmer)
        notify "#{self.class.name} is disabled via Flipper! Bailing out early"
        return
      end

      notify "Starting FacilityGroup caching"
      time = Benchmark.realtime {
        cache_facility_groups
      }
      notify "Finished FacilityGroups caching in #{time.round} seconds."

      notify "Starting Facility caching."
      time = Benchmark.realtime {
        cache_facilities
      }
      end_time = Time.current
      total_time = end_time - start_time
      notify "Finished Facility caching in #{time.round} seconds, total cache time was #{total_time.round} seconds."
      notify "#{self.class.name} All done!"
    ensure
      RequestStore.store[:force_cache] = original_force_cache
    end

    private

    def environment
      ENV["SIMPLE_SERVER_ENV"]
    end

    def notify(msg)
      "#{environment} #{msg}"
    end

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
