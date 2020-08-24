class Period
  include Comparable
  include ActiveModel::Model
  validates :type, presence: true, inclusion: {in: [:month, :quarter], message: "must be month or quarter"}
  validates :value, presence: true

  attr_accessor :type, :value

  def self.month(date)
    new(type: :month, value: date.to_date)
  end

  def self.quarter(value)
    quarter = case value
    when String
      Quarter.parse(value)
    when Date, Time, DateTime
      Quarter.new(date: value)
    when Quarter
      value
    else
      raise ArgumentError, "unknown quarter value #{value} #{value.class}"
    end
    new(type: :quarter, value: quarter)
  end

  def initialize(attributes = {})
    super
    @type = type.intern if type
    @value = if @value.is_a?(String)
      if quarter?
        Quarter.parse(@value)
      else
        @value.to_date
      end
    else
      @value
    end
  end

  # Convert this Period to a quarter period - so:
  #   a Period month of June 2020 will return a quarter Period of Q2-2020
  #   a Period quarter just returns itself
  def to_quarter_period
    return self if quarter?
    self.class.quarter(value)
  end

  def quarter?
    type == :quarter
  end

  def to_date
    value.to_date
  end

  def start_date
    if quarter?
      value.start_date
    else
      value.beginning_of_month.to_date
    end
  end

  def end_date
    if quarter?
      value.end_date
    else
      value.end_of_month.to_date
    end
  end

  def blood_pressure_control_range
    three_months_ago = end_date.advance(months: -3)
    (three_months_ago..end_date)
  end

  def succ
    if quarter?
      Period.new(type: type, value: value.succ)
    else
      Period.new(type: type, value: value.advance(months: 1))
    end
  end

  def previous
    if quarter?
      Period.new(type: type, value: value.previous_quarter)
    else
      Period.new(type: type, value: value.last_month)
    end
  end

  # Return a new period advanced by some number of time units. Note that the period returned will be of the
  # same type. This is provided to be compatible with the underlying Rails advance method, see that method for details:
  # https://api.rubyonrails.org/classes/Date.html#method-i-advance
  def advance(options)
    Period.new(type: type, value: value.advance(options))
  end

  alias eql? ==

  def hash
    value.hash ^ type.hash
  end

  def <=>(other)
    raise ArgumentError, "you are trying to compare a #{other.class} with a Period" unless other.respond_to?(:type)
    raise ArgumentError, "can only compare Periods of the same type" if type != other.type
    value <=> other.value
  end

  def inspect
    "<Period type:#{type} value=#{value}>"
  end

  def to_s
    if quarter?
      value.to_s
    else
      value.to_s(:mon_year)
    end
  end
end
