module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    default_scope { where(experiment_type: %w[stale_patients]) }

    # Eligible patients whose last visit was 35-365 days ago and
    # don't have an appointment in the future.
    #
    # This eligibility test needs to happen on the date of inclusion.
    # The stale experiment reminders are always centered around the experiment_inclusion_date.
    # Unlike the current patient experiment where reminders are scheduled around the expected_return_date,
    # it is not useful to schedule reminders around a date different than the experiment_inclusion_date.
    def eligible_patients(date, filters = {})
      current_month = date.beginning_of_month
      last_visit_since = (date - ENV.fetch("STALE_EXPERIMENT_VISITED_SINCE_DAYS", 365).to_i).beginning_of_day
      last_visit_until = (date - ENV.fetch("STALE_EXPERIMENT_VISITED_UNTIL_DAYS", 35).to_i).end_of_day
      no_appointments_after = date.end_of_day

      self.class.superclass
        .eligible_patients(filters)
        .joins("INNER JOIN reporting_patient_visits ON reporting_patient_visits.patient_id = patients.id")
        .joins("LEFT OUTER JOIN appointments future_appointments
                ON future_appointments.patient_id = patients.id
                AND (future_appointments.scheduled_date > '#{no_appointments_after}'
                      OR future_appointments.remind_on > '#{no_appointments_after}')")
        .where(reporting_patient_visits: {month_date: current_month})
        .where("visited_at > ? AND visited_at < ?", last_visit_since, last_visit_until)
        .where("future_appointments.id IS NULL")
    end

    # Memberships where enrollment date falls on
    # one of the reminder template's remind_on days since `date`.
    #
    # Hotfix: experiment_inclusion_date is currently saved after being converted
    # from a date, into a timestamp with local timezone, and then to utc.
    # So, to get back the correct experiment_inclusion_date, we're reversing that process here.
    def memberships_to_notify(date)
      treatment_group_memberships
        .status_enrolled
        .joins(treatment_group: :reminder_templates)
        .where("date_trunc('day', experiment_inclusion_date) + make_interval(days := reminder_templates.remind_on_in_days) = ?", date)
    end
  end
end
