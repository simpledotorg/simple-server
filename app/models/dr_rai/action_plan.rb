class DrRai::ActionPlan < ApplicationRecord
  include DrRai::Calculatable

  belongs_to :dr_rai_indicator, class_name: "DrRai::Indicator"
  belongs_to :dr_rai_target, class_name: "DrRai::Target"
  belongs_to :region

  validates :statement, presence: true

  def indicator
    dr_rai_indicator
  end

  def target
    dr_rai_target
  end

  def numerator
    indicator.numerator(region)
  end

  def denominator
    target.numeric_value
  end

  def progress
    return 0 unless denominator.positive?
    return 100 unless numerator < denominator

    (numerator.to_f / denominator * 100).round
  end
end
