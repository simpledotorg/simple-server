class Quarter
  include Comparable
  PARSE_REGEX = /\AQ(\d)-(\d{4})\z/

  def self.current
    new(date: Date.current)
  end

  def self.parse(string)
    date = if (match = string.match(PARSE_REGEX))
      number = Integer(match[1])
      year = Integer(match[2])
      quarter_month = quarter_to_month(number)
      Date.new(year, quarter_month).beginning_of_month
    elsif string.respond_to?(:to_date)
      string.to_date
    else
      raise ArgumentError, "Quarter.parse expects a a string in QX-YYYY format or an object that responds to to_date; provided: #{string}"
    end
    new(date: date)
  end

  def self.quarter_to_month(quarter_number)
    ((quarter_number - 1) * 3) + 1
  end

  attr_reader :date
  attr_reader :number
  attr_reader :to_s
  attr_reader :year

  # Create a Quarter with any date-like object, needs to respond to `to_date`. So Date, DateTime, and Time will
  # all work. Note that the stored date is normalized to a proper Date object to keep things consistent.
  def initialize(date:)
    @date = date.to_date.freeze
    @year = date.year.freeze
    @number = QuarterHelper.quarter(date).freeze
    @to_s = "Q#{number}-#{year}".freeze
  end

  def next_quarter
    advance(months: 3)
  end

  alias_method :succ, :next_quarter

  def previous_quarter
    advance(months: -3)
  end

  def advance(options)
    self.class.new(date: date.advance(options))
  end

  def downto(number)
    (1..number).inject([self]) do |quarters, number|
      quarters << quarters.last.previous_quarter
    end
  end

  def upto(number)
    (1..number).inject([self]) do |quarters, number|
      quarters << quarters.last.next_quarter
    end
  end

  def to_date
    date
  end

  def begin
    date.beginning_of_quarter.beginning_of_day
  end

  def end
    date.end_of_quarter.end_of_day
  end

  def to_period
    Period.quarter(self)
  end

  alias_method :beginning_of_quarter, :begin
  alias_method :end_of_quarter, :end

  def inspect
    "#<Quarter:#{object_id} #{to_s.inspect}>"
  end

  def ==(other)
    to_s == other.to_s
  end

  alias_method :eql?, :==

  def <=>(other)
    return -1 if year < other.year
    return -1 if year == other.year && number < other.number
    return 0 if self == other
    return 1 if year > other.year
    return 1 if year == other.year && number > other.number
  end

  def hash
    year.hash ^ number.hash
  end
end
