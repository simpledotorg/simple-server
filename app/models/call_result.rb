class CallResult < ApplicationRecord
  include Mergeable
  belongs_to :appointment, optional: true
  belongs_to :user
  has_one :patient, through: :appointment

  validate :remove_reason_present_if_removed_from_overdue_list
  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :result_type, presence: true
  validates :appointment_id, presence: true

  enum result_type: {
    agreed_to_visit: "agreed_to_visit",
    remind_to_call_later: "remind_to_call_later",
    removed_from_overdue_list: "removed_from_overdue_list"
  }

  enum remove_reason: {
    already_visited: "already_visited",
    not_responding: "not_responding",
    invalid_phone_number: "invalid_phone_number",
    public_hospital_transfer: "public_hospital_transfer",
    moved_to_private: "moved_to_private",
    moved: "moved",
    dead: "dead",
    other: "other"
  }

  private

  def remove_reason_present_if_removed_from_overdue_list
    if result_type == "removed_from_overdue_list" && !remove_reason.present?
      errors.add(:remove_reason, "should be present if removed from overdue list")
    end
  end
end
