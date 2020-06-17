class Quarter
  def self.create(date:)
    new(date: date)
  end

  def self.current
    create(date: Date.current)
  end

  attr_reader :date
  attr_reader :number
  attr_reader :year

  def initialize(date:)
    @date = date.freeze
    @year = date.year.freeze
    @number = QuarterHelper.quarter(date).freeze
  end

  def next_quarter
    self.class.create(date: date.advance(months: 3))
  end

  def previous_quarter
    self.class.create(date: date.advance(months: -3))
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
end