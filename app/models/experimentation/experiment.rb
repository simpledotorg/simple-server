module Experimentation
  class Experiment < ApplicationRecord
    LAST_EXPERIMENT_BUFFER = 14.days.freeze

    has_many :treatment_groups, dependent: :delete_all
    has_many :reminder_templates, through: :treatment_groups
    has_many :patients, through: :treatment_groups
    has_many :notifications

    validates :name, presence: true, uniqueness: true
    validates :experiment_type, presence: true
    validate :validate_date_range
    validate :one_active_experiment_per_type

    enum experiment_type: {
      current_patients: "current_patients",
      stale_patients: "stale_patients",
      medication_reminder: "medication_reminder"
    }

    scope :upcoming, -> { where("start_time > ?", Time.now) }
    scope :running, -> { where("start_time <= ? AND end_time >= ?", Time.now, Time.now) }
    scope :complete, -> { where("end_time <= ?", Time.now) }
    scope :cancelled, -> { with_discarded.discarded }

    def running?
      start_time <= Time.now && end_time >= Time.now
    end

    def self.candidate_patients
      Patient.with_hypertension
        .contactable
        .where_current_age(">=", 18)
        .where("NOT EXISTS (:recent_treatment_group_memberships)",
          recent_treatment_group_memberships: Experimentation::TreatmentGroupMembership
                                         .joins(treatment_group: :experiment)
                                         .where("treatment_group_memberships.patient_id = patients.id")
                                         .where("end_time > ?", LAST_EXPERIMENT_BUFFER.ago)
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
      existing = self.class.running.where(experiment_type: experiment_type).where.not(id: id)

      if existing.any? && running?
        errors.add(:state, "you cannot have multiple active experiments of type #{experiment_type}")
      end
    end

    def validate_date_range
      errors.add(:start_time, "must be present") if start_time.blank?
      errors.add(:end_time, "must be present") if end_time.blank?
      errors.add(:date_range, "start time must precede end time") if start_time.present? && end_time.present? && start_time > end_time
    end
  end
end
