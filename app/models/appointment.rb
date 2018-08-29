class Appointment < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :facility

  enum status: {
    scheduled: 'scheduled',
    cancelled: 'cancelled',
    visited: 'visited'
  }, _prefix: true

  enum status_reason: {
    not_called_yet: 'not_called_yet',
    not_responding: 'not_responding',
    moved: 'moved',
    dead: 'dead'
  }

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true
end