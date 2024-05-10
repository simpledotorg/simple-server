require "prometheus_exporter/client"
require "prometheus_exporter/middleware"

CLIENT = PrometheusExporter::Client.default
REGISTERED_COLLECTORS = {}

class Prometheus
  attr_reader :client, :registered_collectors

  def self.register(type, name, description = nil)
    throw "collector: #{name} is already registered" if REGISTERED_COLLECTORS.has_key?(name)
    REGISTERED_COLLECTORS[name] = CLIENT.register(type, name, description)
  end

  def self.observe(name, value, labels = {})
    throw "collector: #{name} is not registered" unless REGISTERED_COLLECTORS.has_key?(name)
    REGISTERED_COLLECTORS[name].observe(value, labels)
  end
end

if Rails.env.production?
  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
end
