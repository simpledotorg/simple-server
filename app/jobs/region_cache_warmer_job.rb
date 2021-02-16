class RegionCacheWarmerJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(region_id, period_attributes)
    region = Region.find(region_id)
    period = Period.new(period_attributes)
    RequestStore.store[:force_cache] = true

    notify "starting region caching for region #{region_id}"
    Statsd.instance.time("region_cache_warmer.#{region_id}") do
      Reports::RegionService.call(region: region, period: period)
      Statsd.instance.increment("region_cache_warmer.#{region.region_type}.cache")

      Reports::RegionService.call(region: region, period: period, with_exclusions: true)
      Statsd.instance.increment("region_cache_warmer.with_exclusions.#{region.region_type}.cache")
    end
    notify "finished region caching for region #{region_id}"

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
