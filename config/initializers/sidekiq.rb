module SidekiqConfig
  DEFAULT_SIDEKIQ_REDIS_POOL_SIZE = 12

  def self.connection_pool
    ConnectionPool.new(size: Config.get_int('SIDEKIQ_REDIS_POOL_SIZE',
                                            DEFAULT_SIDEKIQ_REDIS_POOL_SIZE)) do
      Redis.new(host: ENV['SIDEKIQ_REDIS_HOST'])
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = SidekiqConfig.connection_pool
end

Sidekiq.configure_server do |config|
  config.redis = SidekiqConfig.connection_pool
end
