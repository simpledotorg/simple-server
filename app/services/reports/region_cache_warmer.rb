class Reports::RegionCacheWarmer
  def self.call
    new.call
  end

  def initialize(period: RegionService.default_period)
    @period = period
  end

  delegate :logger, to: Rails

  def call
    FacilityGroup.all.each do |region|
      logger.info { "class=#{self.class.name} region=#{region.name}" }
      Reports::RegionService.new(region: region, period: @period).call
    end
    Facility.all.each do |region|
      logger.info { "class=#{self.class.name} region=#{region.name}" }
      Reports::RegionService.new(region: region, period: @period).call
    end
  end
end