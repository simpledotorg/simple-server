class SetLocalTimezone
  def call(_worker, _job, _queue)
    Time.use_zone(Rails.application.config.country[:time_zone] || "UTC") { yield }
  end
end

module SidekiqConfig
  DEFAULT_REDIS_POOL_SIZE = 12

  Sidekiq::Extensions.enable_delay!

  def self.connection_pool
    ConnectionPool.new(size: Config.get_int("SIDEKIQ_REDIS_POOL_SIZE", DEFAULT_REDIS_POOL_SIZE)) do
      if ENV["SIDEKIQ_REDIS_HOST"].present?
        Redis.new(host: ENV["SIDEKIQ_REDIS_HOST"])
      else
        Redis.new
      end
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = SidekiqConfig.connection_pool
end

SIDEKIQ_STATS_KEY = "worker"
SIDEKIQ_STATS_PREFIX = "#{SIMPLE_SERVER_ENV}.#{CountryConfig.current[:abbreviation]}"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SetLocalTimezone
    # The env and prefix are used to create keys in the format of env.prefix.worker_name.[stat_name]
    # We want 'sidekiq' to be the top level, and then have our env specific information,
    # which is we pass in a static string to `env` and the actual server env to `prefix`.
    chain.add Sidekiq::Statsd::ServerMiddleware, env: SIDEKIQ_STATS_KEY, prefix: SIDEKIQ_STATS_PREFIX, statsd: Statsd.instance.statsd
  end
  config.redis = SidekiqConfig.connection_pool
end

require "sidekiq/throttled"
Sidekiq::Throttled.setup!
