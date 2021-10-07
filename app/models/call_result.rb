class CallResult < ApplicationRecord
  include Mergeable
  belongs_to :appointment, optional: true
  belongs_to :user

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validates :result_type, presence: true
  validates :appointment_id, presence: true

  enum result_type: {
    agreed_to_visit: "agreed_to_visit",
    removed_from_overdue_list: "removed_from_overdue_list",
    remind_to_call_later: "remind_to_call_later"
  }

  enum remove_reason: {
    not_responding: "not_responding",
    moved: "moved",
    dead: "dead",
    invalid_phone_number: "invalid_phone_number",
    public_hospital_transfer: "public_hospital_transfer",
    moved_to_private: "moved_to_private",
    other: "other"
  }
end
