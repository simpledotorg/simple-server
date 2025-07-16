require "sidekiq-unique-jobs"
require "sidekiq/throttled"
require "prometheus_exporter/instrumentation"

Dir.glob(Rails.root.join("lib", "sidekiq_middleware", "**", "*.rb")).sort.each { |f| require f }

module SidekiqConfig
  DEFAULT_REDIS_POOL_SIZE = 12

  Sidekiq::Extensions.enable_delay!

  def self.connection_pool
    ConnectionPool.new(size: EnvHelper.get_int("SIDEKIQ_REDIS_POOL_SIZE", DEFAULT_REDIS_POOL_SIZE)) do
      if ENV["SIDEKIQ_REDIS_HOST"].present?
        Redis.new(host: ENV["SIDEKIQ_REDIS_HOST"])
      else
        Redis.new
      end
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = SidekiqConfig.connection_pool

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

SIDEKIQ_STATS_KEY = "worker"
SIDEKIQ_STATS_PREFIX = "#{SimpleServer.env}.#{CountryConfig.current[:abbreviation]}"

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add PrometheusExporter::Instrumentation::Sidekiq
  end
  config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler

  config.on :startup do
    PrometheusExporter::Instrumentation::Process.start type: "sidekiq"
    PrometheusExporter::Instrumentation::SidekiqProcess.start
    PrometheusExporter::Instrumentation::SidekiqQueue.start
    PrometheusExporter::Instrumentation::SidekiqStats.start
    PrometheusExporter::Instrumentation::ActiveRecord.start(
      custom_labels: {type: "sidekiq"},
      config_labels: [:database, :host]
    )
  end

  config.on(:shutdown) do
    PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqMiddleware::SetLocalTimeZone
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.redis = SidekiqConfig.connection_pool

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.logger.level = Rails.logger.level

Sidekiq::Throttled.setup!
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end
