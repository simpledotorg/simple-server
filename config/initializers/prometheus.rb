require "prometheus_exporter/client"
require "prometheus_exporter/middleware"

Dir.glob(Rails.root.join("lib", "prometheus_middleware", "**", "*.rb")).sort.each { |f| require f }

if Rails.env.production?
  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift SimplePrometheusMiddleware
end
