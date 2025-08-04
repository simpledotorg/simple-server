# Dr Rai Indicator
#
# This is the entity. From a data perspective, this entity is complete as is.
# However, there is logic layered on this entity which does not allow it be
# complete by itself. Other "logical" entities are layered ontop of this one to
# make the feature complete. So while vaildations may pass, the entity may
# still be functionally unusable if used by itself. If you want to create an
# indicator, look to one of the child classes.
class DrRai::Indicator < ApplicationRecord
  DEFAULT_RANGE = Range.new(Period.current.advance(months: -6), Period.current)

  # Consider this an abstract class which forces child classes to implement
  # specific functionality. Ruby does not have abstract classes so this is the
  # best we can do technique-wise
  include DrRai::Calculatable

  # There should only ever be one instance of any indicator in the db
  validates :type, uniqueness: true

  has_one :target, class_name: "DrRai::Target", dependent: :destroy, foreign_key: "dr_rai_indicators_id"
  accepts_nested_attributes_for :target

  def quarterlies(region)
    data = Reports::RegionSummary.call(region, range: DEFAULT_RANGE)
    Reports::RegionSummary.group_by(grouping: :quarter, data: data)[region.slug]
  end

  def period
    Period.new(type: :quarter, value: target.period)
  end

  def target_type
    DrRai::Target::TYPES[target_type_frontend]
  end

  def numerator(region, the_period = period)
    numerators(region)[the_period]
  end

  def denominator(region, the_period = period)
    denominators(region)[the_period]
  end

  def numerators(region)
    datasource(region).map do |t, data|
      [t, data[numerator_key]]
    end.to_h
  end

  def denominators(region)
    datasource(region).map do |t, data|
      [t, data[denominator_key]]
    end.to_h
  end

  def action
    [unit, action_passive].join(" ")
  end
end
