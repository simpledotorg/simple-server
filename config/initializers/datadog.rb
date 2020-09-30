require "ddtrace"
require "datadog/statsd"

if ["sandbox", "production"].include?(SIMPLE_SERVER_ENV)
  Datadog.configure do |c|
    c.use :rails, service_name: "#{SIMPLE_SERVER_ENV}-rails-app"
  end
end
