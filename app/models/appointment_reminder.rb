class AppointmentReminder < ApplicationRecord
  belongs_to :appointment
  belongs_to :patient
  belongs_to :experiment, class_name: "Experimentation::Experiment", optional: true
  belongs_to :reminder_template, class_name: "Experimentation::ReminderTemplate", optional: true
  has_many :communications

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true

  enum status: {
    pending: "pending",
    scheduled: "scheduled",
    sent: "sent",
    cancelled: "cancelled"
  }, _prefix: true
end
