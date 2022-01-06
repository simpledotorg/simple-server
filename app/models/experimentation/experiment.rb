# frozen_string_literal: true

module Experimentation
  class Experiment < ApplicationRecord
    # RECENT_EXPERIMENT_MEMBERSHIP_BUFFER should be at least as big as
    # MONITORING_BUFFER otherwise patients who are being monitored
    # in an experiment can be considered eligible for an upcoming experiment.
    MONITORING_BUFFER = 15.days.freeze
    RECENT_EXPERIMENT_MEMBERSHIP_BUFFER = 15.days.freeze

    has_many :treatment_groups, dependent: :delete_all
    has_many :reminder_templates, through: :treatment_groups
    has_many :treatment_group_memberships, through: :treatment_groups
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

    scope :upcoming, -> { where("start_time > ?", Time.current) }
    scope :running, -> { where("start_time <= ? AND end_time >= ?", Time.current, Time.current) }
    scope :monitoring, -> { where("start_time <= ? AND end_time > ?", Time.current, Time.current - MONITORING_BUFFER) }
    scope :completed, -> { where("end_time < ?", Time.current - MONITORING_BUFFER) }
    scope :cancelled, -> { with_discarded.discarded }

    def running?
      start_time <= Time.current && end_time >= Time.current
    end

    def random_treatment_group
      raise "random treatment group requested for experiment with no treatment groups" unless treatment_groups.any?
      treatment_groups.sample
    end

    def cancel
      discard
      logger.info "Cancelled experiment #{name}."
    end

    private

    def one_active_experiment_per_type
      existing_experiments = self.class.where(experiment_type: experiment_type).where.not(id: id)
      any_overlap = existing_experiments.any? { |experiment| overlap?(experiment) }

      errors.add(:state, "you cannot have multiple active experiments of type #{experiment_type}") if any_overlap
    end

    def overlap?(other_experiment)
      !((start_time < other_experiment.start_time && end_time < other_experiment.start_time) ||
        (start_time > other_experiment.end_time && end_time > other_experiment.end_time))
    end

    def validate_date_range
      errors.add(:start_time, "must be present") if start_time.blank?
      errors.add(:end_time, "must be present") if end_time.blank?
      errors.add(:date_range, "start time must precede end time") if start_time.present? && end_time.present? && start_time > end_time
    end
  end
end
