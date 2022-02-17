class RedisService
  def initialize(connection)
    @connection = connection
  end

  def hmset_with_expiry(key, value_hash, ttl)
    @connection.pipelined do |pipeline|
      pipeline.hmset(key, *value_hash)
      pipeline.expire(key, ttl)
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
