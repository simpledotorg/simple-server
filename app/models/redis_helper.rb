class RedisHelper
  def initialize(connection)
    @connection = connection
  end

  def hmset_with_expiry(key, value_hash, ttl)
    execute do
      @connection.pipelined do
        @connection.hmset(key, *value_hash)
        @connection.expire(key, ttl)
      end
    end
  end

  def hgetall(key)
    data = execute { @connection.hgetall(key) }
    data.symbolize_keys if data.present?
  end

  def del(key)
    execute { @connection.del(key) }
  end

  def execute
    yield
  rescue => exception
    Raven.capture_message(
      'Error while executing the redis command',
      logger: 'logger',
      extra: {
        exception: exception.to_s
      },
      tags: { type: 'redis-store' })
  end
end
