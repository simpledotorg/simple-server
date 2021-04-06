class RegionCacheWarmerJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_options queue: :default
  # sidekiq_throttle(concurrency: {limit: ENV["REGION_CACHE_WARMER_CONCURRENCY"] || DEFAULT_CONCURRENCY_LIMIT})

  def perform(region_id, period_attributes)
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
