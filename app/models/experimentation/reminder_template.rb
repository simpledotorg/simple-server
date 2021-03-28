module Experimentation
  class ReminderTemplate < ActiveRecord::Base
    belongs_to :treatment_cohort
    has_many :appointment_reminders

    validates :message, presence: true
    validates :appointment_offset, presence: true, numericality: { only_integer: true }
  end
end
