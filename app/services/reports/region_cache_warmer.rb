module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def self.create_slack_notifier
      return if ENV["SLACK_ALERTS_WEBHOOK_URL"].blank?
      Slack::Notifier.new(ENV["SLACK_ALERTS_WEBHOOK_URL"], channel: "#alerts", username: "simple-server")
    end

    def initialize(period: RegionService.default_period)
      @notifier = self.class.create_slack_notifier
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
        notify "disabled via flipper - exiting"
        return
      end

      notify "starting facility_group caching"
      Statsd.instance.time("region_cache_warmer.facility_groups") do
        cache_facility_groups
      end

      notify "starting facility caching"
      Statsd.instance.time("region_cache_warmer.facilities") do
        cache_facilities
      end
      notify "finished"
    ensure
      RequestStore.store[:force_cache] = original_force_cache
    end

    private

    def notify(msg)
      Rails.logger.info msg: msg, class: self.class.name
    end

    def cache_facility_groups
      FacilityGroup.all.each do |region|
        RegionService.new(region: region, period: period).call
      end
    end

    def cache_facilities
      Facility.all.each do |region|
        RegionService.new(region: region, period: period).call
      end
    end
  end
end
