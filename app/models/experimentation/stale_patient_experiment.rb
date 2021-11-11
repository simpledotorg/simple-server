module Experimentation
  class StalePatientExperiment < NotificationsExperiment
    PATIENT_VISITED_SINCE = -365.days.freeze
    PATIENT_VISITED_UNTIL = -35.days.freeze

    default_scope { where(experiment_type: %w[stale_patients]) }

    # Eligible patients whose last visit was 35-365 days ago and
    # don't have an appointment in the future.
    def eligible_patients(date)
      parameters = {
        hypertension: "yes",
        current_month: date.beginning_of_month,
        last_visit_since: (date + PATIENT_VISITED_SINCE).beginning_of_day,
        last_visit_until: (date + PATIENT_VISITED_UNTIL).end_of_day,
        no_appointments_after: date.end_of_day
      }
      sql = GitHub::SQL.new(<<~SQL, parameters)
        SELECT patient_id FROM reporting_patient_visits
          WHERE month_date = :current_month
          AND visited_at > :last_visit_since AND visited_at < :last_visit_until
          AND NOT EXISTS
          (SELECT 1 FROM appointments
              WHERE appointments.patient_id = reporting_patient_visits.patient_id
              AND appointments.scheduled_date >= :no_appointments_after)
      SQL

      self.class.superclass.eligible_patients.where(id: sql.values)
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
