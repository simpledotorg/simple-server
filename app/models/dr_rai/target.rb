class DrRai::Target < ApplicationRecord
  TYPES = {
    "percent" => "DrRai::PercentageTarget",
    "numeric" => "DrRai::NumericTarget",
    "boolean" => "DrRai::BooleanTarget"
  }

  validates :period, presence: true, format: {with: /\AQ\d-\d{4}\Z/}
end
