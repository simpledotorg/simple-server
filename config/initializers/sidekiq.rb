class SetLocalTimezone
  def call(_worker, _job, _queue)
    begin
      Time.use_zone(ENV['DEFAULT_TIME_ZONE'] || 'UTC') do
        yield
      end
    rescue => ex
      puts ex.message
    end
  end
end

module SidekiqConfig
  DEFAULT_REDIS_POOL_SIZE = 12

  Sidekiq::Extensions.enable_delay!

  def self.connection_pool
    ConnectionPool.new(size: Config.get_int('SIDEKIQ_REDIS_POOL_SIZE', DEFAULT_REDIS_POOL_SIZE)) do
      Redis.new(host: ENV['SIDEKIQ_REDIS_HOST'])
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = SidekiqConfig.connection_pool
end

Sidekiq.configure_server do |config|
  config.server_middleware { |chain| chain.add SetLocalTimezone }
  config.redis = SidekiqConfig.connection_pool
end

require "sidekiq/throttled"
Sidekiq::Throttled.setup!
