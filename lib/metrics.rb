class Metrics
  def self.with_object(object)
    prefix = object.class.name.underscore.tr("/", ".")
    new(prefix)
  end

  def self.with_prefix(prefix)
    new(prefix)
  end

  def initialize(prefix)
    @prefix = prefix
  end

  def increment(event)
    name = "#{@prefix}.#{event}"
    Statsd.instance.increment(name)
  end
end
