module Experimentation
  class TreatmentGroup < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates, dependent: :delete_all
    has_many :treatment_group_memberships
    has_many :patients, through: :treatment_group_memberships

    validates :index, presence: true, numericality: {greater_than_or_equal_to: 0}
    validates :description, presence: true
  end
end
