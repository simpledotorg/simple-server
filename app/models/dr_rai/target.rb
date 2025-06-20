class DrRai::Target < ApplicationRecord
  belongs_to :indicator, class_name: 'DrRai::Indicator', foreign_key: 'dr_rai_indicators_id'

  validates :period, presence: true

  # Default grouping is quarterly
  def grouping
    Period.new(period).type
  end
end
