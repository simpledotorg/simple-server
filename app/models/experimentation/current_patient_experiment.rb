module Experimentation
  class CurrentPatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[current_patients]) }

    def eligible_patients(date, filters = {})
      appointment_date = date - earliest_remind_on.days

      self.class.superclass
        .eligible_patients(filters)
        .joins(:appointments)
        .merge(Appointment.status_scheduled)
        .where("appointments.scheduled_date BETWEEN ? and ?", appointment_date.beginning_of_day, appointment_date.end_of_day)
        .distinct
    end

    # Memberships where the expected return date falls on
    # one of the reminder template's remind_on days since `date`.
    #
    # Hotfix: expected_return_date is currently saved after being converted
    # from a date, into a timestamp with local timezone, and then to utc.
    # So, to get back the correct expected_return_date, we're reversing that process here.
    def memberships_to_notify(date)
      treatment_group_memberships
        .status_enrolled
        .joins(treatment_group: :reminder_templates)
        .where("date_trunc('day', expected_return_date) + make_interval(days := reminder_templates.remind_on_in_days) = ?", date)
    end
  end
end
