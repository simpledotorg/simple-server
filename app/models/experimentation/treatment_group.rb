module Experimentation
  class TreatmentGroup < ActiveRecord::Base
    belongs_to :experiment
    has_many :reminder_templates, dependent: :delete_all
    has_many :treatment_group_memberships
    has_many :patients, through: :treatment_group_memberships

    validates :description, presence: true, uniqueness: {scope: :experiment_id}

    def enroll(patient)
      Experimentation::TreatmentGroupMembership.create(
        treatment_group_id: id,
        treatment_group_name: description,
        patient_id: patient.id,
        experiment_id: experiment.id,
        experiment_name: experiment.name
      )
    end
  end
end
