require "simple_server_extensions"
require "ddtrace"
require "datadog/statsd"

# Allow running via an ENV var (for development usage, for example) ...otherwise
# exclude some envs by default
DATADOG_ENABLED = ENV["DATADOG_ENABLED"] || !(Rails.env.development? || Rails.env.test? || Rails.env.profiling? || SimpleServer.env.review? || SimpleServer.env.android_review?)

Datadog.configure do |c|
  c.tracing.enabled = DATADOG_ENABLED
  c.profiling.enabled = false
  c.version = SimpleServer.git_ref(short: true)
  c.tracing.instrument :rack, headers: {request: %w[X-USER-ID X-FACILITY-ID X-SYNC-REGION-ID X-APP-VERSION], response: %w[Content-Type X-Request-ID]}
  c.tracing.instrument :rake
  c.tracing.instrument :rails, analytics_enabled: true
  c.tracing.instrument :sidekiq, analytics_enabled: true, service_name: "sidekiq", analytics_sample_rate: 0.005
end

require "statsd"
require "metrics"
