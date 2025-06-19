class DrRai::Target < ApplicationRecord
  validates :period, presence: true

  # Default grouping is quarterly
  def grouping
    Period.new(period).type
  end
end
