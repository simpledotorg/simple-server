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

    def record_notification(notification)
      # TODO: localized_message can blow up assigned facility is discarded
      self.messages ||= {}
      self.messages[notification.message] = {
        remind_on: notification.remind_on,
        status: notification.status,
        notification_id: notification.id,
        localized_message: notification.localized_message
      }
      save!
    end

    def record_notification_result(message, delivery_result)
      messages[message].merge!(delivery_result)
      save!
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
