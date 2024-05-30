require "prometheus_exporter/client"
require "prometheus_exporter/middleware"

CLIENT = PrometheusExporter::Client.default
REGISTERED_COLLECTORS = {}

class Prometheus
  attr_reader :client, :registered_collectors

  def self.register(type, name, description = nil)
    raise "collector: #{name} is already registered" if exists?(name)
    REGISTERED_COLLECTORS[name] = CLIENT.register(type, name, description)
  end

  def self.observe(name, value, labels = {})
    raise "collector: #{name} is not registered" unless exists?(name)
    REGISTERED_COLLECTORS[name].observe(value, labels)
  end

  def self.exists?(name)
    REGISTERED_COLLECTORS.has_key?(name)
  end
end

if Rails.env.production?
  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware
end
