class DrRai::Target < ApplicationRecord
  TYPES = {
    "percent" => "DrRai::PercentageTarget",
    "numeric" => "DrRai::NumericTarget",
    "boolean" => "DrRai::BooleanTarget"
  }

  NEEDS_STATEMENT = %w[ percent numeric ].map { |t| TYPES[t] }.freeze

  belongs_to :indicator, class_name: "DrRai::Indicator", foreign_key: "dr_rai_indicators_id"

  validates :period, presence: true, format: {with: /\AQ\d-\d{4}\Z/}
end
