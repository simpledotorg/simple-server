class AppointmentReminder < ApplicationRecord
  belongs_to :experiment, optional: true
  belongs_to :appointment

  validates_presence_of :status

  enum status: {
    pending: "pending",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
end
