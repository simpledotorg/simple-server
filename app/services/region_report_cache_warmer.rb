class RegionReportCacheWarmer
  def initialize(period: Date.current.to_period)
    @period = period
  end

  def call
    FacilityGroup.all.each do |region|
      p "region #{region} #{region.name}"
      p "region facilities: #{region.facilities.map(&:to_s)}"
      RegionReportService.new(region: region, period: @period).call
    end
  end
end