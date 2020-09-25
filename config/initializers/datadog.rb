if ["sandbox", "production"].include?(SIMPLE_SERVER_ENV)
  require "ddtrace"
  require "datadog/statsd"
  Datadog.configure do |c|
    c.use :rails, service_name: "#{SIMPLE_SERVER_ENV}-rails-app", log_injection: true
  end
end
