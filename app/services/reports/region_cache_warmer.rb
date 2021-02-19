module Reports
  class RegionCacheWarmer
    def self.call
      new.call
    end

    def initialize(period: RegionService.default_period)
      @period = period
      notify "queueing region reports cache warming"
    end

    attr_reader :period

    def call
      if Flipper.enabled?(:disable_region_cache_warmer)
        notify "disabled via flipper - exiting"
        return
      end

      Region.where.not(region_type: ["root", "organization"]).pluck(:id).each do |region_id|
        RegionCacheWarmerJob.perform_async(region_id, period.attributes)
      end

      notify "queued region reports cache warming"
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
