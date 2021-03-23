module Experiment
  class ReminderTemplate < ActiveRecord::Base
    belongs_to :reminder_experiment
    has_many :appointment_reminders

    validates :experiment_group, presence: true
    validates :message, presence: true
    validates :appointment_offset, presence: true
  end
end
