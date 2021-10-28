module Experimentation
  class TreatmentGroupMembership < ActiveRecord::Base
    belongs_to :treatment_group
    belongs_to :patient
    belongs_to :experiment

    validate :one_active_experiment_per_patient

    enum status: {
      enrolled: "enrolled",
      visited: "visited",
      evicted: "evicted"
    }, _prefix: true

    private

    def one_active_experiment_per_patient
      existing_memberships =
        self.class
          .joins(treatment_group: :experiment)
          .merge(Experiment.running)
          .where(patient_id: patient_id)

      errors.add(:patient_id, "patient cannot belong to multiple active experiments") if existing_memberships.any?
    end
  end
end
