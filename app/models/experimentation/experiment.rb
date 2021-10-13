module Experimentation
  class Experiment < ActiveRecord::Base
    has_many :treatment_groups, dependent: :delete_all
    has_many :reminder_templates, through: :treatment_groups
    has_many :patients, through: :treatment_groups
    has_many :notifications

    validates :name, presence: true, uniqueness: true
    validates :state, presence: true
    validates :experiment_type, presence: true
    validate :validate_date_range
    validate :one_active_experiment_per_type

    enum state: {
      new: "new",
      selecting: "selecting",
      running: "running",
      cancelled: "cancelled",
      complete: "complete"
    }, _suffix: true

    enum experiment_type: {
      current_patients: "current_patients",
      stale_patients: "stale_patients",
      medication_reminder: "medication_reminder"
    }

    def self.candidate_patients
      Patient.with_hypertension
        .contactable
        .where("age >= ?", 18)
        .includes(treatment_group_memberships: [treatment_group: [:experiment]])
        .where(["experiments.end_date < ? OR experiments.id IS NULL", Runner::LAST_EXPERIMENT_BUFFER.ago]).references(:experiment)
    end

    def random_treatment_group
      treatment_groups.sample
    end

    private

    def one_active_experiment_per_type
      existing = self.class.where(state: ["running", "selecting"], experiment_type: experiment_type)
      existing = existing.where("id != ?", id) if persisted?
      if existing.any?
        errors.add(:state, "you cannot have multiple active experiments of type #{experiment_type}")
      end
    end

    def validate_date_range
      errors.add(:start_date, "must be present") if start_date.blank?
      errors.add(:end_date, "must be present") if end_date.blank?
      errors.add(:date_range, "start date must precede end date") if start_date.present? && end_date.present? && start_date > end_date
    end
  end
end
