class Sidekiq::Middleware::Server::SetLocalTimezone
  def call(_worker, _job, _queue)
    begin
      Time.use_zone(ENV['DEFAULT_TIME_ZONE'] || 'UTC') { yield }
    rescue => ex
      puts ex.message
    end
  end
end
