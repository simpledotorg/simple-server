require "prometheus_exporter/client"
class Prometheus
  include Singleton

  def initialize
    @client = PrometheusExporter::Client.default
    @collectors = {}
  end

  def register(type, name, description = nil)
    @collectors[name] ||= @client.register(type, name, description)
    self
  end

  def observe(name, value, labels = {})
    @collectors[name].observe(value, labels)
  end
end
