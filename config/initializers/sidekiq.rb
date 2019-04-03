DEFAULT_SIDEKIQ_REDIS_POOL_SIZE = 12

sidekiq_connection_pool = lambda do
  ConnectionPool.new(size: Config.get_int('SIDEKIQ_REDIS_POOL_SIZE',
                                          DEFAULT_SIDEKIQ_REDIS_POOL_SIZE)) do
    Redis.new(host: ENV['SIDEKIQ_REDIS_HOST'])
  end
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_connection_pool.call
end

Sidekiq.configure_server do |config|
  config.redis = sidekiq_connection_pool.call
end
