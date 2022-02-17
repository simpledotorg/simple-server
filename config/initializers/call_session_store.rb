require "connection_pool"

module CallSessionStore
  DEFAULT_REDIS_POOL_SIZE = 12
  DEFAULT_REDIS_TIMEOUT_SEC = 1

  def self.create_redis(args)
    Redis.new(args)
  end

  CONNECTION_PARAMETERS = {
    size: EnvHelper.get_int("CALL_SESSION_REDIS_POOL_SIZE", DEFAULT_REDIS_POOL_SIZE),
    timeout: EnvHelper.get_int("CALL_SESSION_REDIS_TIMEOUT_SEC", DEFAULT_REDIS_TIMEOUT_SEC)
  }

  CONNECTION_POOL = ConnectionPool.new(CONNECTION_PARAMETERS) {
    if ENV["CALL_SESSION_REDIS_HOST"].present?
      create_redis(host: ENV["CALL_SESSION_REDIS_HOST"])
    else
      create_redis
    end
  }
end
