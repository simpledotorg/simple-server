# frozen_string_literal: true

class RedisService
  def initialize(connection)
    @connection = connection
  end

  def hmset_with_expiry(key, value_hash, ttl)
    @connection.pipelined do
      @connection.hmset(key, *value_hash)
      @connection.expire(key, ttl)
    end
  end

  def hgetall(key)
    data = @connection.hgetall(key)
    data.symbolize_keys if data.present?
  end

  def del(key)
    @connection.del(key)
  end
end
