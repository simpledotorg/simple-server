module Experiment
  class ReminderExperiment < ActiveRecord::Base
    has_many :reminder_templates

    validates :active, presence: true
  end
end
