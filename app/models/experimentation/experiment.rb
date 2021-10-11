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
      # Patient
      # .contactable
      # .with_hypertension
      # .where("age >= ?", 18)
      #   .where.not(id: Experimentation::TreatmentGroupMembership
      #                    .joins(treatment_group: :experiment)
      #                    .where("end_date > ?", Runner::LAST_EXPERIMENT_BUFFER.ago)
      #                    .select(:patient_id))


      #
      #   Patient
      #     .where("
      #     NOT EXISTS(
      #         SELECT patient_id
      #         FROM treatment_group_memberships
      #         INNER JOIN treatment_groups ON treatment_groups.id = treatment_group_memberships.treatment_group_id
      #         INNER JOIN experiments ON experiments.id = treatment_groups.experiment_id
      #         WHERE treatment_group_memberships.patient_id = patients.id
      #         AND end_date > now() - interval '14 days')")
      #
      #
      # SELECT "treatment_group_memberships"."patient_id"
      # FROM "treatment_group_memberships"
      # INNER JOIN "treatment_groups" ON "treatment_groups"."id" = "treatment_group_memberships"."treatment_group_id"
      # INNER JOIN "experiments" ON "experiments"."id" = "treatment_groups"."experiment_id"
      # WHERE (end_date > '2021-09-27 10:10:17.974508')

      Patient.where("NOT EXISTS (:treatment_group_memberships)",
                    treatment_group_memberships: Experimentation::TreatmentGroupMembership
                                                   .joins(treatment_group: :experiment)
                                                   .where("treatment_group_memberships.patient_id = patients.id")
                                                   .where("end_date > ?", Runner::LAST_EXPERIMENT_BUFFER.ago)
                                                   .select(:patient_id))


      # Patient
      #   .joins("left join lateral (
      #          select distinct on (patient_id) end_date from experiments
      #          inner join treatment_group_memberships tgm on tgm.patient_id = patients.id
      #          inner join treatment_groups tg on tg.id = tgm.treatment_group_id
      #          where patient_id = patients.id
      #          order by patient_id, end_date desc
      #         ) latest_end_date ON TRUE")
      #   .where("end_date < now() - interval '14 days' OR end_date IS NULL").to_sql

      # Patient
      #   .joins("left outer join treatment_group_memberships ON treatment_group_memberships.patient_id = patients.id ")
      #   .joins("left outer join treatment_groups ON treatment_groups.id = treatment_group_memberships.treatment_group_id")
      #   .joins("left outer join experiments ON experiments.id = treatment_groups.experiment_id ON end_date > ?", Runner::LAST_EXPERIMENT_BUFFER.ago)
      #   .where("experiments.id IS NULL")



      # Patient.where(id:
      #                 Patient
      #                   .select("distinct on (patients.id) patients.id, experiments.end_date")
      #                   .joins("left outer join treatment_group_memberships ON treatment_group_memberships.patient_id = patients.id ")
      #                   .joins("left outer join treatment_groups ON treatment_groups.id = treatment_group_memberships.treatment_group_id")
      #                   .joins("left outer join experiments ON experiments.id = treatment_groups.experiment_id")
      #                   .order("patients.id, experiments.end_date desc")
      # )
      #   .where("end_date < ? OR experiments.id IS NULL", Runner::LAST_EXPERIMENT_BUFFER.ago)
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
