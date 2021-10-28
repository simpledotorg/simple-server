class Period
  REPORTING_TIME_ZONE = CountryConfig.current[:time_zone] || "Asia/Kolkata"

  include Comparable
  include ActiveModel::Model
  validates :type, presence: true, inclusion: {in: [:month, :quarter], message: "must be month or quarter"}
  validates :value, presence: true

  attr_accessor :type, :value

  # Return the current month Period
  def self.current
    month(Date.current)
  end

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

  # Return the common formatteer so groupdate can return Period keys instead of dates
  def self.formatter(period_type)
    lambda { |v| period_type == :quarter ? Period.quarter(v) : Period.month(v) }
  end

  # Create a Period with an attributes hash of type and value.
  # Note that we call super here to allow ActiveModel::Model to setup the attributes hash.
  def initialize(attributes = {})
    super
    self.type = type.intern if type
    self.value = if quarter?
      self.class.cast_to_quarter(value)
    else
      value.to_date.beginning_of_month
    end
    validate!
  end

  def attributes
    {type: type, value: value}
  end

  # Returns a new Period adjusted by the registration buffer. This is used in our denominators to determine
  # control rates, so that new patients aren't included in the calculations.
  def adjusted_period
    advance(months: -Reports::REGISTRATION_BUFFER_IN_MONTHS)
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

  def ltfu_since_date
    self.begin.advance(months: -12).end_of_month.to_s(:day_mon_year)
  end

  def month?
    type == :month
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
    raise ArgumentError, "you are trying to compare a #{other.class} with a Period" unless other.respond_to?(:type) && other.respond_to?(:value)
    return nil if type != other.type
    value <=> other.value
  end

  alias_method :eql?, :==

  def inspect
    "<Period type:#{type} value=#{value}>"
  end

  def to_s(format = :default_period)
    value.to_s(format)
  end

  # Returns a Hash with various Period related dates for eash consumption by the view
  def to_hash
    @to_hash ||= {
      name: to_s,
      ltfu_since_date: ltfu_since_date,
      bp_control_start_date: bp_control_range_start_date,
      bp_control_end_date: bp_control_range_end_date,
      bp_control_registration_date: bp_control_registrations_until_date
    }
  end

  def adjective
    "#{type.capitalize}ly"
  end
end
