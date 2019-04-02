DEFAULT_SIDEKIQ_REDIS_POOL_SIZE = 12

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: ENV['SIDEKIQ_REDIS_POOL_SIZE'].to_i || DEFAULT_SIDEKIQ_REDIS_POOL_SIZE) do
    Redis.new(host: ENV['SIDEKIQ_REDIS_CLIENT_HOST'])
  end
end

Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: ENV['SIDEKIQ_REDIS_POOL_SIZE'].to_i || DEFAULT_SIDEKIQ_REDIS_POOL_SIZE) do
    Redis.new(host: ENV['SIDEKIQ_REDIS_SERVER_HOST'])
  end
end
