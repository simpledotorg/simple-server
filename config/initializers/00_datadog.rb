require "ddtrace"
require "datadog/statsd"

unless Rails.env.development? || Rails.env.test?
  Datadog.configure do |c|
    c.use :rails,
      analytics_enabled: true,
      service_name: "#{SIMPLE_SERVER_ENV}-rails-app"
  end
end
