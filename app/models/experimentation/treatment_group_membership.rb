module Experimentation
  class TreatmentGroupMembership < ActiveRecord::Base
    belongs_to :treatment_group
    belongs_to :patient
    belongs_to :experiment
    belongs_to :appointment, optional: true

    validate :one_active_experiment_per_patient, if: -> {
      patient_id_changed? || treatment_group_id_changed? || experiment_id_changed?
    }

    enum status: {
      enrolled: "enrolled",
      visited: "visited",
      evicted: "evicted"
    }, _prefix: true

    def self.evict(reason:)
      update_all(status: :evicted, status_updated_at: Time.current, status_reason: reason)
    end

    def record_notification(notification)
      reload # this is to reload the `messages` field to avoid staleness while updating.
      self.messages ||= {}
      self.messages[notification.message] = {
        remind_on: notification.remind_on,
        notification_status: notification.status,
        notification_id: notification.id,
        localized_message: notification.localized_message,
        notification_status_updated_at: notification.updated_at.to_s,
        created_at: notification.created_at.to_s
      }
      save!
    end

    def record_notification_result(message, delivery_result)
      reload.messages[message].merge!(delivery_result)
      save!
    end

    def record_visit(blood_pressure:, blood_sugar:, prescription_drug:)
      visits = [blood_pressure, blood_sugar, prescription_drug].compact
      return if visits.blank?

      earliest_visit = visits.min_by(&:recorded_at)
      visit_date = earliest_visit.recorded_at
      visit_facility = earliest_visit.facility

      update!(
        visit_blood_pressure_id: blood_pressure&.id,
        visit_blood_sugar_id: blood_sugar&.id,
        visit_prescription_drug_created: prescription_drug.present?,
        visit_date: visit_date,
        visit_facility_id: visit_facility.id,
        visit_facility_name: visit_facility.name,
        visit_facility_type: visit_facility.facility_type,
        visit_facility_block: visit_facility.block,
        visit_facility_district: visit_facility.district,
        visit_facility_state: visit_facility.state,
        status: :visited,
        status_updated_at: Time.current,
        status_reason: :visit_recorded,
        days_to_visit: (visit_date.to_date - experiment_inclusion_date.to_date).to_i
      )
    end

    private

    def one_active_experiment_per_patient
      existing_memberships =
        self.class
          .joins(treatment_group: :experiment)
          .merge(Experiment.running)
          .where(patient_id: patient_id)
          .where.not(experiments: {id: id})

      errors.add(:patient_id, "patient cannot belong to multiple active experiments") if existing_memberships.any?
    end
  end
end
