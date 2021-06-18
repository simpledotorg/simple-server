require "simple_server_extensions"
require "ddtrace"
require "datadog/statsd"

# We want Datadog to run everywhere, but we won't have the DD agent running
# in dev, test, or on Heroku - so we don't want to send payloads there.
SEND_DATA_TO_DD_AGENT = !(Rails.env.development? || Rails.env.test? || SimpleServer.env.review?)

Datadog.configure do |c|
  c.tracer.enabled = SEND_DATA_TO_DD_AGENT
  c.version = SimpleServer.git_ref(short: true)
  c.use :rails, analytics_enabled: true
  c.use :rack, headers: {request: %w[X-USER-ID X-FACILITY-ID X-SYNC-REGION-ID], response: %w[Content-Type X-Request-ID]}
  c.use :sidekiq, analytics_enabled: true
end

require "statsd"
require "metrics"

# This is a workaround for https://youtrack.jetbrains.com/issue/RUBY-27489
if defined?(:Debase)
  if Datadog::VERSION::STRING != "0.50.0"
    raise "Since you updated ddtrace, please check if this workaround is still needed"
  end

  module FixThreadLocalContext
    def local(thread = Thread.current)
      thread[@key] ||= Datadog::Context.new
    end
  end

  Datadog::ThreadLocalContext.prepend FixThreadLocalContext
end
