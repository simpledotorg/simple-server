class DrRai::ActionPlan < ApplicationRecord
  include DrRai::Calculatable

  belongs_to :dr_rai_indicator, class_name: "DrRai::Indicator"
  belongs_to :dr_rai_target, class_name: "DrRai::Target"
  belongs_to :region
  has_many :action_items,
    -> { order(:position) },
    class_name: "DrRai::ActionItem",
    inverse_of: :action_plan,
    dependent: :destroy

  validates :statement, presence: true, if: :target_uses_statement?

  after_create :build_items_from_actions
  before_discard :discard_action_items

  def self.items_from_actions_text(text)
    text.to_s.lines.map(&:strip).reject(&:blank?)
  end

  def self.backfill_action_items!
    with_discarded.find_each do |plan|
      next if plan.action_items.exists?

      plan.build_items_from_actions
    end
  end

  def build_items_from_actions
    return if action_items.exists?
    return if actions.blank?

    self.class.items_from_actions_text(actions).each_with_index do |body, index|
      action_items.create!(body: body, position: index)
    end
  end

  # Replaces the task list. Rows with an id keep completed_at. Blank bodies are dropped.
  def replace_action_items!(raw_items)
    transaction do
      kept_ids = []
      position = 0

      Array(raw_items).each do |item|
        attributes = item.to_h.symbolize_keys
        body = attributes[:body].to_s.strip
        next if body.blank?

        if attributes[:id].present? && (record = action_items.find_by(id: attributes[:id]))
          record.update!(body: body, position: position)
          kept_ids << record.id
        else
          created = action_items.create!(body: body, position: position)
          kept_ids << created.id
        end
        position += 1
      end

      obsolete = kept_ids.empty? ? action_items : action_items.where.not(id: kept_ids)
      obsolete.find_each(&:discard)
      update_column(:actions, action_items.reload.map(&:body).join("\n"))
    end
    true
  end

  def tasks_checkable?(on: Date.current)
    return false if target.nil? || target.period.blank?

    quarter = Period.new(type: :quarter, value: target.period)
    start_on = quarter.begin.to_date
    end_on = quarter.end.to_date.next_month.end_of_month
    on.to_date.between?(start_on, end_on)
  end

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

  def discard_action_items
    action_items.find_each(&:discard)
  end
end
