class DrRai::ActionItem < ApplicationRecord
  belongs_to :action_plan, class_name: "DrRai::ActionPlan", inverse_of: :action_items

  validates :body, presence: true
  validates :position, presence: true

  def completed?
    completed_at.present?
  end
end
