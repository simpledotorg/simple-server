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
        last_visit_since: (date + PATIENT_VISITED_SINCE).beginning_of_day,
        last_visit_until: (date + PATIENT_VISITED_UNTIL).end_of_day,
        no_appointments_after: date.end_of_day
      }
      sql = GitHub::SQL.new(<<~SQL, parameters)
        SELECT DISTINCT patients.id
        FROM patients
        INNER JOIN medical_histories mh
         ON patients.id = mh.patient_id
        LEFT JOIN appointments on appointments.patient_id = patients.id
          AND appointments.device_created_at BETWEEN :last_visit_since AND :last_visit_until
        LEFT JOIN prescription_drugs on prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at BETWEEN :last_visit_since AND :last_visit_until
        LEFT JOIN blood_sugars on blood_sugars.patient_id = patients.id
          AND blood_sugars.device_created_at BETWEEN :last_visit_since AND :last_visit_until
        LEFT JOIN blood_pressures on blood_pressures.patient_id = patients.id
          AND blood_pressures.device_created_at BETWEEN :last_visit_since AND :last_visit_until
        WHERE patients.deleted_at IS NULL
          AND mh.hypertension = :hypertension
          AND (appointments.id IS NOT NULL
            OR prescription_drugs.id IS NOT NULL
            OR blood_sugars.id IS NOT NULL
            OR blood_pressures.id IS NOT NULL)
          AND NOT EXISTS
            (SELECT 1 FROM appointments WHERE appointments.patient_id = patients.id
               AND appointments.scheduled_date >= :no_appointments_after)
      SQL

      self.class.superclass.eligible_patients.where(id: sql.values)
    end

    def memberships_to_notify(date)
      # Patients who were enrolled on the `date`.
      # To be implemented in a follow up PR.
    end
  end
end
