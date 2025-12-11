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

  def quarterlies(region)
    data = Reports::RegionSummary.call(region, range: DEFAULT_RANGE)
    Reports::RegionSummaryAggregator.new(data).quarterly(with: :sum)[region.slug]
  end

  def has_action_plans?(region, period)
    raise "Must use a quarter period" unless period.type == :quarter
    raise "Must use a Region type" unless region.is_a? Region

    @region_exists ||= DrRai::ActionPlan
      .joins(:dr_rai_indicator)
      .joins(:dr_rai_target)
      .where(
        region: region,
        dr_rai_target: {
          period: period.value.to_s
        },
        dr_rai_indicator: {
          type: type
        }
      ).exists?
  end

  def target_type
    DrRai::Target::TYPES[target_type_frontend]
  end

  def numerator(region, the_period, with_non_contactable: nil)
    return 0 unless is_supported?(region)
    numerators(region, all: with_non_contactable)[the_period]
  end

  def denominator(region, the_period, with_non_contactable: nil)
    return 0 unless is_supported?(region)
    denominators(region, all: with_non_contactable)[the_period]
  end

  def numerators(region, all: nil)
    return {} unless is_supported?(region)
    data_source = datasource(region)
    return {} if data_source.nil?
    data_source.map do |t, data|
      [t, data[numerator_key(all: all)]]
    end.to_h
  end

  def denominators(region, all: nil)
    return {} unless is_supported?(region)
    data_source = datasource(region)
    return {} if data_source.nil?
    data_source.map do |t, data|
      [t, data[denominator_key(all: all)]]
    end.to_h
  end

  def action
    [unit, action_passive].join(" ")
  end
end
