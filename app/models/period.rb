class Period
  include Comparable
  include ActiveModel::Model
  attr_accessor :type, :value

  def initialize(attributes = {})
    super
    @type = type.intern if type
  end

  def <=>(other)
    value <=> other.value
  end

  validates :type, presence: true, inclusion: {in: [:month, :quarter], message: "must be month or quarter"}
  validates :value, presence: true
end
