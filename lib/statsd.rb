class Statsd
  include Singleton

  def reset!
    @statsd = nil
  end

  def statsd
    @statsd ||= create_connection
  end

  def close
    @statsd&.flush
    @statsd&.close
    @statsd = nil
  end

  delegate :count, :increment, :time, :timing, :gauge, to: :statsd

  private

  def create_connection
    Datadog::Statsd.new("localhost", 8125)
  end
end
