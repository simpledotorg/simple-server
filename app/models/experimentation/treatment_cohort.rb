module Experimentation
  class TreatmentCohort < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates

    validates :bucketing_index, presence: true, numericality: { :greater_than_or_equal_to => 0 }
    validates :description, presence: true
  end
end
