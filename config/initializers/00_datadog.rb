require "simple_server_extensions"
require "ddtrace"
require "datadog/statsd"

# Allow running via an ENV var (for development usage, for example) ...otherwise
# exclude some envs by default
DATADOG_ENABLED = ENV["DATADOG_ENABLED"] || !(Rails.env.development? || Rails.env.test? || SimpleServer.env.review?)

# Trying out Ruby code profiling in selected environments
ENABLE_DD_PROFILING = SimpleServer.env.sandbox?

Datadog.configure do |c|
  c.tracer.enabled = DATADOG_ENABLED
  c.profiling.enabled = ENABLE_DD_PROFILING
  c.version = SimpleServer.git_ref(short: true)
  c.use :rack, headers: {request: %w[X-USER-ID X-FACILITY-ID X-SYNC-REGION-ID X-APP-VERSION], response: %w[Content-Type X-Request-ID]}
  c.use :rake
  c.use :rails, analytics_enabled: true
  c.use :sidekiq, analytics_enabled: true
end

require "statsd"
require "metrics"
