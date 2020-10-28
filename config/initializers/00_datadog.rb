require "simple_server_extensions"
require "ddtrace"
require "datadog/statsd"

# We want Datadog to run everywhere, but we won't have the DD agent running
# in dev and test so we don't want to send payloads there.
SEND_DATA_TO_DD_AGENT = !(Rails.env.development? || Rails.env.test?)

Datadog.configure do |c|
  c.tracer.enabled = SEND_DATA_TO_DD_AGENT
  c.version = SimpleServer.git_ref(short: true)
  c.use :rails, analytics_enabled: true
  c.use :rack, headers: {request: ["X-USER-ID", "X-FACILITY-ID", "X-SYNC-REGION-ID"], response: ["Content-Type", "X-Request-ID"]}
end

require "statsd"
