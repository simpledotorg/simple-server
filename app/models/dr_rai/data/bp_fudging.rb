class DrRai::Data::BpFudging < ApplicationRecord
  include DrRai::Chartable

  QUARTERS = ->(timeline = 1.year.ago..Date.today) {
    Period.quarters_between(timeline.begin, timeline.end)
      .map(&:to_s)
  }

  default_scope { where(quarter: QUARTERS.call(10.months.ago..2.months.from_now)) }
  scope :insert_window, ->(timeline) { where(quarter: QUARTERS.call(timeline)) }

  chartable_internal_keys :numerator, :denominator, :ratio
  chartable_period_key :quarter
  chartable_outer_grouping :slug
end
