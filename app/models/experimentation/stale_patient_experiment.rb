module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[stale_patients]) }

    def eligible_patients(date)
      appointment_date = date - reminder_templates.pluck(:remind_on_in_days).min.days

      Patient.where(id: StalePatientSelection.call(date: appointment_date))
    end

    def memberships_for_notifications(date)
      # Patients who were enrolled on the `date`.
      # To be implemented in a follow up PR.
    end
  end
end
