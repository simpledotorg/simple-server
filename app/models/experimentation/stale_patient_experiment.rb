module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    PATIENT_VISITED_SINCE = -365.days.freeze
    PATIENT_VISITED_UNTIL = -35.days.freeze

    default_scope { where(experiment_type: %w[stale_patients]) }

    # Eligible patients whose last visit was 35-365 days ago and
    # don't have an appointment in the future.
    def eligible_patients(date)
      current_month = date.beginning_of_month
      staleness_date = date - earliest_remind_on.days
      last_visit_since = (staleness_date + PATIENT_VISITED_SINCE).beginning_of_day
      last_visit_until = (staleness_date + PATIENT_VISITED_UNTIL).end_of_day
      no_appointments_after = staleness_date.end_of_day

      self.class.superclass.eligible_patients
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
    def memberships_to_notify(date)
      treatment_group_memberships
        .status_enrolled
        .joins(treatment_group: :reminder_templates)
        .where("experiment_inclusion_date::timestamp + make_interval(days := reminder_templates.remind_on_in_days) = ?", date)
    end
  end
end
