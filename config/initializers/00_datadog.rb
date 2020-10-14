require "ddtrace"
require "datadog/statsd"

# We want Datadog to run everywhere, but we won't have the DD agent running
# in dev and test so we don't want to send payloads there.
SEND_DATA_TO_DD_AGENT = !(Rails.env.development? || Rails.env.test?)

CURRENT_GIT_REF = if Rails.root.join("REVISION").exist?
  Rails.root.join("REVISION").read
else
  `git rev-parse HEAD`.chomp
end

Datadog.configure do |c|
  c.tracer.enabled = SEND_DATA_TO_DD_AGENT
  c.version = CURRENT_GIT_REF
  c.use :rails, analytics_enabled: true
end

require "statsd"
