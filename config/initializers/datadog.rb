if SIMPLE_SERVER_ENV == "sandbox"
  require "ddtrace"
  Datadog.configure do |c|
    c.use :rails, service_name: "#{SIMPLE_SERVER_ENV}-rails-app", log_injection: true
  end
end
