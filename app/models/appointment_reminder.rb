class AppointmentReminder < ApplicationRecord
  belongs_to :patient
  belongs_to :experiment, optional: true
  belongs_to :appointment
  has_many :communications

  enum status: {
    pending: "pending",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
end