class DrRai::Data::Titration < ApplicationRecord
  include DrRai::Chartable

  default_scope { where(month_date: 1.year.ago..Date.today) }

  chartable_internal_keys :follow_up_count, :titrated_count
  chartable_period_key :month_date
  chartable_outer_grouping :facility_name
end
