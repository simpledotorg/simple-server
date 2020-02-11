class Sidekiq::Middleware::Server::SetLocalTimezone
  def call(_worker, _job, _queue)
    begin
      Time.use_zone(Rails.application.config.country[:time_zone] || 'UTC') { yield }
    rescue => ex
      puts ex.message
    end
  end
end
