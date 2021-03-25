class AppointmentReminder < ApplicationRecord
  belongs_to :appointment
  belongs_to :patient
  belongs_to :experiment, optional: true
  belongs_to :reminder_template, optional: true

  validates :status, presence: true
  validates :remind_on, presence: true
  validates :message, presence: true

  enum status: [:pending, :sent, :cancelled], _prefix: true
end
