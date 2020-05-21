require "connection_pool"

module CallSessionStore
  DEFAULT_REDIS_POOL_SIZE = 12
  DEFAULT_REDIS_TIMEOUT_SEC = 1

  CONNECTION_PARAMETERS = {
    size: Config.get_int("CALL_SESSION_REDIS_POOL_SIZE", DEFAULT_REDIS_POOL_SIZE),
    timeout: Config.get_int("CALL_SESSION_REDIS_TIMEOUT_SEC", DEFAULT_REDIS_TIMEOUT_SEC)
  }

  CONNECTION_POOL = ConnectionPool.new(CONNECTION_PARAMETERS) {
    if ENV["CALL_SESSION_REDIS_HOST"].present?
      Redis.new(host: ENV["CALL_SESSION_REDIS_HOST"])
    else
      Redis.new
    end
  }
end
