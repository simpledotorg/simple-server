class Quarter
  include Comparable
  PARSE_REGEX = /\AQ(\d)-(\d{4})\z/

  def self.for_date(date)
    new(date: date)
  end

  def self.current
    new(date: Date.current)
  end

  def self.parse(string)
    match = string.match(PARSE_REGEX)
    raise ArgumentError, "String to parse as Quarter must match QX-YYYY format" unless match
    number = Integer(match[1])
    year = Integer(match[2])
    quarter_month = quarter_to_month(number)
    date = Date.new(year, quarter_month).beginning_of_month
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

  alias succ next_quarter

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

  def start_date
    date.beginning_of_quarter
  end

  alias beginning_of_quarter start_date

  def end_date
    date.end_of_quarter
  end

  alias end_of_quarter end_date

  def to_period
    Period.quarter(self)
  end

  def inspect
    "#<Quarter:#{object_id} #{to_s.inspect}>"
  end

  def ==(other)
    to_s == other.to_s
  end

  def <=>(other)
    return -1 if year < other.year
    return -1 if year == other.year && number < other.number
    return 0 if self == other
    return 1 if year > other.year
    return 1 if year == other.year && number > other.number
  end

  alias eql? ==

  def hash
    year.hash ^ number.hash
  end
end
