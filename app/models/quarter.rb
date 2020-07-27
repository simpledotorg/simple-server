class Quarter
  PARSE_REGEX = /\AQ(\d)-(\d{4})\z/

  def self.current
    new(date: Date.current)
  end

  def self.parse(string)
    match = string.match(PARSE_REGEX)
    raise ArgumentError, "String to parse as Quarter must match QX-YYYY format" unless match
    number = Integer(match[1])
    year = Integer(match[2])
    quarter_month = ((number - 1) * 3) + 1
    date = Date.new(year, quarter_month).beginning_of_month
    new(date: date)
  end

  attr_reader :date
  attr_reader :number
  attr_reader :year

  def initialize(date:)
    @date = date.freeze
    @year = date.year.freeze
    @number = QuarterHelper.quarter(date).freeze
    @to_s = "Q#{number}-#{year}".freeze
  end

  def next_quarter
    self.class.new(date: date.advance(months: 3))
  end

  def previous_quarter
    self.class.new(date: date.advance(months: -3))
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

  def inspect
    "#<Quarter:#{object_id} #{to_s.inspect}>"
  end

  def to_s
    @to_s
  end

  def ==(other)
    to_s == other.to_s
  end

  alias eql? ==

  def hash
    year.hash ^ number.hash
  end

end
