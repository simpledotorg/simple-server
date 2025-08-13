class DrRai::Data::Titration < ApplicationRecord
  default_scope { where(month_date: 1.year.ago..Date.today) }
end
