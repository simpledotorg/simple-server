module Experiment
  class ReminderExperiment < ActiveRecord::Base
    has_many :reminder_templates
  end
end
