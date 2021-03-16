class AppointmentReminder < ApplicationRecord
  belongs_to :patient
  belongs_to :experiment
  belongs_to :appointment
  has_many :communications
end