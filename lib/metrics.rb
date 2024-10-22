module Metrics
  extend self

  def gauge(event, count, labels = {}, description = nil)
    record_metric(:gauge, event, count, labels, description)
  end

  def increment(event, labels = {}, description = nil)
    record_metric(:counter, event, 1, labels, description)
  end

  def histogram(event, count, labels = {}, description = nil)
    record_metric(:histogram, event, count, labels, description)
  end

  def summary(event, count, labels = {}, description = nil)
    record_metric(:summary, event, count, labels, description)
  end

  def benchmark_and_gauge(event, labels = {}, description = nil, &block)
    raise ArgumentError, "Block must be provided" unless block
    benchmark_and_record_metric(:gauge, event, labels, description, &block)
  end

  def benchmark_and_histogram(event, labels = {}, description = nil, &block)
    raise ArgumentError, "Block must be provided" unless block
    benchmark_and_record_metric(:histogram, event, labels, description, &block)
  end

  def benchmark_and_summary(event, labels = {}, description = nil, &block)
    raise ArgumentError, "Block must be provided" unless block
    benchmark_and_record_metric(:summary, event, labels, description, &block)
  end

  private

  def record_metric(type, event, count, labels = {}, description = nil)
    return unless Rails.env.production?
    Prometheus
      .instance
      .register(type, event, description)
      .observe(event, count, labels)
  end

  def benchmark_and_record_metric(type, event, labels, description)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
  ensure
    elapsed_time_seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    record_metric(type, event, elapsed_time_seconds, labels, description)
  end

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
end
