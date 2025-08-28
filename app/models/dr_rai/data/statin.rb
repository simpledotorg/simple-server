class DrRai::Data::Statin < ApplicationRecord
  include DrRai::Chartable

  default_scope { where(month_date: 1.year.ago..Date.today) }

  chartable_internal_keys :eligible_patients, :patients_prescribed_statins
  chartable_period_key :month_date
  chartable_outer_grouping :aggregate_root
end
