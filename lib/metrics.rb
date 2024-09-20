class Metrics
  def self.with_object(object)
    prefix = object.class.name.underscore.tr("/", "_")
    new(prefix)
  end

  def self.with_prefix(prefix)
    new(prefix)
  end

  def initialize(prefix)
    @prefix = prefix
  end

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
    benchmark_and_metric(:gauge, event, labels, description, &block)
  end

  def benchmark_and_histogram(event, labels = {}, description = nil, &block)
    raise ArgumentError, "Block must be provided" unless block
    benchmark_and_metric(:histogram, event, labels, description, &block)
  end

  def benchmark_and_summary(event, labels = {}, description = nil, &block)
    raise ArgumentError, "Block must be provided" unless block
    benchmark_and_metric(:summary, event, labels, description, &block)
  end

  private

  def record_metric(type, event, count, labels = {}, description = nil)
    name = "#{@prefix}_#{event}".downcase
    Prometheus
      .instance
      .register(type, name, description)
      .observe(name, count, labels)
  end

  def benchmark_and_metric(type, event, labels, description)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
  ensure
    elapsed_time_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round
    record_metric(type, event, elapsed_time_ms, labels, description)
  end
end
