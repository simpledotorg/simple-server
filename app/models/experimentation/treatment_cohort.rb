module Experimentation
  class TreatmentCohort < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates

    validates :cohort_identifier, presence: true
  end
end
