class Appointment < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :communications

  enum status: {
    scheduled: 'scheduled',
    cancelled: 'cancelled',
    visited: 'visited'
  }, _prefix: true

  enum cancel_reason: {
    not_responding: 'not_responding',
    moved: 'moved',
    dead: 'dead',
    invalid_phone_number: 'invalid_phone_number',
    public_hospital_transfer: 'public_hospital_transfer',
    moved_to_private: 'moved_to_private',
    other: 'other'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
  validate :cancel_reason_is_present_if_cancelled

  def cancel_reason_is_present_if_cancelled
    if status == :cancelled && !cancel_reason.present?
      errors.add(:cancel_reason, "should be present for cancelled appointments")
    end
  end

  def overdue?
    (status == :scheduled ||
     status == 'scheduled') &&
      Date.today > scheduled_date
  end
end