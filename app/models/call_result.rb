class CallResult < ApplicationRecord

  belongs_to :appointment
  belongs_to :user

  enum cancel_reason: {
    not_responding: "not_responding",
    moved: "moved",
    dead: "dead",
    invalid_phone_number: "invalid_phone_number",
    public_hospital_transfer: "public_hospital_transfer",
    moved_to_private: "moved_to_private",
    other: "other"
  }

end
