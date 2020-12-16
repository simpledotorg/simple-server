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
  c.use :action_view, analytics_enabled: true
  c.use :active_record, analytics_enabled: true
  c.use :action_pack, analytics_enabled: true
  c.use :active_support, analytics_enabled: true
  c.use :rack, headers: {request: ["X-USER-ID", "X-FACILITY-ID", "X-SYNC-REGION-ID"], response: ["Content-Type", "X-Request-ID"]}
end

require "statsd"
