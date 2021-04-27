class Period
  include Comparable
  include ActiveModel::Model
  validates :type, presence: true, inclusion: {in: [:month, :quarter], message: "must be month or quarter"}
  validates :value, presence: true

  attr_accessor :type, :value

  REGISTRATION_BUFFER_MONTHS = 3

  def self.month(date)
    new(type: :month, value: date.to_date)
  end

  def self.quarter(value)
    quarter = cast_to_quarter(value)
    new(type: :quarter, value: quarter)
  end

  def self.cast_to_quarter(value)
    case value
    when String
      Quarter.parse(value)
    when Date, Time, DateTime
      Quarter.new(date: value)
    when Quarter
      value
    else
      raise ArgumentError, "unknown quarter value #{value} #{value.class}"
    end
  end

  def initialize(attributes = {})
    super
    self.type = type.intern if type
    self.value = if quarter?
      self.class.cast_to_quarter(value)
    else
      value.to_date.beginning_of_month
    end
  end

  def attributes
    {type: type, value: value}
  end

  def adjusted_period
    advance(months: -REGISTRATION_BUFFER_MONTHS)
  end

  # Convert this Period to a quarter period - so:
  #   a Period month of June 2020 will return a quarter Period of Q2-2020
  #   a Period quarter just returns itself
  def to_quarter_period
    return self if quarter?
    self.class.quarter(value)
  end

  # Returns a range of times that correspond to the 'BP control range' for this period.
  # For example, for a reporting period of July 1st 2020, this will return the times of April 30th..July 31st.
  def blood_pressure_control_range
    start_time = advance(months: -2).begin
    (start_time..end_time)
  end

  alias_method :bp_control_range, :blood_pressure_control_range

  def bp_control_registrations_until_date
    adjusted_period.end.to_s(:day_mon_year)
  end

  def bp_control_range_start_date
    bp_control_range.begin.to_s(:day_mon_year)
  end

  def bp_control_range_end_date
    bp_control_range.end.to_s(:day_mon_year)
  end

  def quarter?
    type == :quarter
  end

  def to_date
    value.to_date
  end

  def begin
    if quarter?
      value.begin
    else
      value.beginning_of_month.beginning_of_day
    end
  end
  alias_method :start_time, :begin

  def end
    if quarter?
      value.end
    else
      value.end_of_month.end_of_day
    end
  end
  alias_method :end_time, :end

  def succ
    if quarter?
      Period.new(type: type, value: value.succ)
    else
      Period.new(type: type, value: value.advance(months: 1))
    end
  end

  alias_method :next, :succ

  def previous
    if quarter?
      Period.new(type: type, value: value.previous_quarter)
    else
      Period.new(type: type, value: value.last_month)
    end
  end

  def downto(number)
    (1..number).inject([self]) do |periods, number|
      periods << periods.last.previous
    end
  end

  # Return a new period advanced by some number of time units. Note that the period returned will be of the
  # same type. This is provided to be compatible with the underlying Rails advance method, see that method for details:
  # https://api.rubyonrails.org/classes/Date.html#method-i-advance
  def advance(options)
    Period.new(type: type, value: value.advance(options))
  end

  def cache_key
    "#{type}/#{self}"
  end

  def hash
    value.hash ^ type.hash
  end

  def <=>(other)
    raise ArgumentError, "you are trying to compare a #{other.class} with a Period" unless other.respond_to?(:type)
    return nil if type != other.type
    value <=> other.value
  end

  alias_method :eql?, :==

  def inspect
    "<Period type:#{type} value=#{value}>"
  end

  def to_s(format = :mon_year)
    if quarter?
      value.to_s
    else
      value.to_s(format)
    end
  end

  def adjective
    "#{type.capitalize}ly"
  end
end
