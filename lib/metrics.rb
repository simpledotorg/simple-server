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
    name = "#{@prefix}_#{event}"
    Prometheus
      .instance
      .register(:gauge, name, description)
      .observe(name, count, labels)
  end

  def increment(event, labels = {}, description = nil)
    name = "#{@prefix}_#{event}"
    Prometheus
      .instance
      .register(:counter, name, description)
      .observe(name, 1, labels)
  end

  def histogram(event, count, labels = {}, description = nil)
    name = "#{@prefix}_#{event}"
    Prometheus
      .instance
      .register(:histogram, name, description)
      .observe(name, count, labels)
  end

  def summary(event, count, labels = {}, description = nil)
    name = "#{@prefix}_#{event}"
    Prometheus
      .instance
      .register(:summary, name, description)
      .observe(name, count, labels)
  end
end
