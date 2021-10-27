module Experimentation
  class CurrentPatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[current_patients]) }

    def eligible_patients(date)
      appointment_date = date - earliest_remind_on.days

      self.class.superclass.eligible_patients
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", appointment_date.beginning_of_day, appointment_date.end_of_day)
        .distinct
    end

    def memberships_to_notify(date)
      # Patients where `date` equals one of their reminder template's remind_on.
      # To be implemented in a follow up PR.
    end

    private

    def earliest_remind_on
      reminder_templates.pluck(:remind_on_in_days).min || 0
    end
  end
end
