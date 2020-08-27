module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def initialize(period: RegionService.default_period)
      @period = period
      @original_force_cache = RequestStore.store[:force_cache]
      RequestStore.store[:force_cache] = true
    end

    attr_reader :original_force_cache, :period
    delegate :logger, to: Rails

    def call
      FacilityGroup.all.each do |region|
        logger.info { "class=#{self.class.name} region=#{region.name}" }
        RegionService.new(region: region, period: period).call
      end
      Facility.all.each do |region|
        logger.info { "class=#{self.class.name} region=#{region.name}" }
        RegionService.new(region: region, period: period).call
      end
    ensure
      RequestStore.store[:force_cache] = original_force_cache
    end
  end
end
