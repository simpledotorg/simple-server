module Experimentation
  class TreatmentGroup < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates, dependent: :delete_all
    has_many :treatment_group_memberships
    has_many :patients, through: :treatment_group_memberships

    validates :description, presence: true, uniqueness: {scope: :experiment_id}
  end
end
