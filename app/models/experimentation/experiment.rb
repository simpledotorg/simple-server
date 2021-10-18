module Experimentation
  class Experiment < ActiveRecord::Base
    LAST_EXPERIMENT_BUFFER = 14.days.freeze

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
        .where_current_age(">=", 18)
        .where("NOT EXISTS (:recent_treatment_group_memberships)",
          recent_treatment_group_memberships: Experimentation::TreatmentGroupMembership
                                         .joins(treatment_group: :experiment)
                                         .where("treatment_group_memberships.patient_id = patients.id")
                                         .where("end_date > ?", LAST_EXPERIMENT_BUFFER.ago)
                                         .select(:patient_id))
        .where("NOT EXISTS (:multiple_scheduled_appointments)",
          multiple_scheduled_appointments: Appointment
                                            .select(1)
                                            .where("appointments.patient_id = patients.id")
                                            .where(status: :scheduled)
                                            .group(:patient_id)
                                            .having("count(patient_id) > 1"))
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
