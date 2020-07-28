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
      Quarter.for_date(value)
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
  end

  def quarter?
    type == :quarter
  end

  def <=>(other)
    value <=> other.value
  end

  def to_s
    if quarter?
      value.to_s
    else
      value.to_s(:month_year)
    end
  end

  def to_date
    value.to_date
  end

  def succ
    if quarter?
      Period.new(type: type, value: value.succ)
    else
      Period.new(type: type, value: value.next_month)
    end
  end

  # def ==(other)
  #   value == other.value && type == other.type
  # end

  alias eql? ==

  def hash
    value.hash ^ type.hash
  end
end
