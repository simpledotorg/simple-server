if Rails.env.production?
  require "prometheus_exporter/middleware"

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
end
