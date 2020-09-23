if SIMPLE_SERVER_ENV == "sandbox"
  require "ddtrace"
  Datadog.configure do |c|
    c.analytics_enabled = true
    c.use :http
    c.use :rails, service_name: "#{SIMPLE_SERVER_ENV}-rails-app"
    c.use :sidekiq
  end
end
