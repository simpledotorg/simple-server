require 'connection_pool'

connection_parameters = {
  size: 5,
  timeout: 1000.to_i / 1000
}

CALL_SESSION_STORE_POOL = ConnectionPool.new(connection_parameters) do
  Redis.new(host: 'localhost',
            port: 6379)
end
