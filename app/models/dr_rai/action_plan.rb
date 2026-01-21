class DrRai::ActionPlan < ApplicationRecord
  include DrRai::Calculatable

  belongs_to :dr_rai_indicator, class_name: "DrRai::Indicator"
  belongs_to :dr_rai_target, class_name: "DrRai::Target"
  belongs_to :region

  validates :statement, presence: true, if: :target_uses_statement?

  def indicator
    dr_rai_indicator
  end

  def target
    dr_rai_target
  end

  def numerator
    target_period = Period.new(type: :quarter, value: target.period)
    indicator.numerator(region, target_period)
  end

  def denominator
    target.numeric_value
  end

  def progress
    return 0 if unprocessible?
    return 100 unless numerator < denominator

    (numerator.to_f / denominator * 100).round
  end

  def unit
    indicator.unit
  end

  def passive_action
    indicator.action_passive
  end

  def current_ratio
    return nil unless custom_target?
    datasource = indicator.datasource(region)
    return nil unless datasource
    period = Period.new(type: :quarter, value: target.period)
    data = datasource[period]
    data&.dig(:ratio)
  end

  def previous_ratio
    return nil unless custom_target?
    datasource = indicator.datasource(region)
    return nil unless datasource
    period = Period.new(type: :quarter, value: target.period)
    previous_period = period.previous
    data = datasource[previous_period]
    data&.dig(:ratio)
  end

  def ratio_change_percentage
    return nil unless custom_target?
    return nil if current_ratio.nil? || previous_ratio.nil?
    return nil if previous_ratio == 0
    ((current_ratio - previous_ratio) / previous_ratio * 100).round
  end

  def is_better?
    return nil unless custom_target?
    return nil if current_ratio.nil? || previous_ratio.nil?
    # For BP Fudging, lower ratio is better
    current_ratio < previous_ratio
  end

  def custom_target?
    target.type == "DrRai::CustomTarget"
  end

  private

  def unprocessible?
    denominator.negative? ||
      numerator.nil?
  end

  def target_uses_statement?
    DrRai::Target::NEEDS_STATEMENT.include?(indicator.type)
  end
end
