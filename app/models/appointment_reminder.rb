class AppointmentReminder < ApplicationRecord
  belongs_to :experiment, optional: true
  belongs_to :appointment

  validates_presence_of :status
  validates_presence_of :remind_on

  enum status: {
    pending: "pending",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
end
