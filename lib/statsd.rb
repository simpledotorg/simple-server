class Statsd
  include Singleton

  def initialize
    @statsd = Datadog::Statsd.new("localhost", 8125)
  end

  attr_reader :statsd

  delegate :increment, :time, :timing, :gauge, to: :statsd
end
