module Experimentation
  class NotificationsExperiment < Experiment
    include Memery
    MAX_PATIENTS_PER_DAY = 2000

    default_scope { where(experiment_type: %w[current_patients stale_patients]) }
    scope :notifying, -> do
      joins(treatment_groups: :reminder_templates)
        .where("start_time <= ? AND end_time + make_interval(days := remind_on_in_days) > ? ", Time.current, Time.current)
        .distinct
    end

    def self.daily_run(date)
      running.each { |experiment| experiment.enroll_patients(date) }
      monitoring.each { |experiment| experiment.monitor(date) }
      notifying.each { |experiment| experiment.send_notifications(date) }
    end

    # Returns patients who are eligible for enrollment. These should be
    # filtered further by individual notification experiments based on their criteria.
    def self.eligible_patients
      Patient.with_hypertension
        .contactable
        .where_current_age(">=", 18)
        .where("NOT EXISTS (:recent_experiment_memberships)",
          recent_experiment_memberships: Experimentation::TreatmentGroupMembership
                                           .joins(treatment_group: :experiment)
                                           .where("treatment_group_memberships.patient_id = patients.id")
                                           .where("end_time > ?", RECENT_EXPERIMENT_MEMBERSHIP_BUFFER.ago)
                                           .select(:patient_id))
        .where("NOT EXISTS (:multiple_scheduled_appointments)",
          multiple_scheduled_appointments: Appointment
                                             .select(1)
                                             .where("appointments.patient_id = patients.id")
                                             .where(status: :scheduled)
                                             .group(:patient_id)
                                             .having("count(patient_id) > 1"))
    end

    def enroll_patients(date)
      self.class.eligible_patients(date)
        .limit(MAX_PATIENTS_PER_DAY)
        .then { |patients| assign_treatment_group(patients) }
    end

    def monitor(date)
      # for enrolled_patients
      mark_visits
      evict_patients
    end

    def mark_visits
    end

    def evict_patients
    end

    def send_notifications(date)
    end

    def enrolled_patients
      Patient.where(id: treatment_group_memberships.status_enrolled.select(:patient_id))
    end
  end
end
