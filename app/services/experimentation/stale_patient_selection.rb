module Experimentation
  class StalePatientSelection
    ELIGIBILITY_START = 365.days.freeze
    ELIGIBILITY_END = 35.days.freeze

    def self.call(*args)
      new(*args).call
    end

    attr_reader :start_time
    attr_reader :eligible_range

    def initialize(start_time:)
      @start_time = start_time
      range_start = (start_time - ELIGIBILITY_START).beginning_of_day
      range_end = (start_time - ELIGIBILITY_END).end_of_day
      @eligible_range = (range_start..range_end)
    end

    def call
      candidate_ids = NotificationsExperiment.candidate_patients.pluck(:id)
      return [] if candidate_ids.empty?

      parameters = {
        candidate_ids: candidate_ids,
        hypertension: "yes",
        range_start: eligible_range.begin,
        range_end: eligible_range.end,
        start_time: start_time
      }
      sql = GitHub::SQL.new(<<~SQL, parameters)
        SELECT DISTINCT patients.id
        FROM patients
        INNER JOIN medical_histories mh
         ON patients.id = mh.patient_id
        LEFT JOIN appointments on appointments.patient_id = patients.id
          AND appointments.device_created_at BETWEEN :range_start AND :range_end
        LEFT JOIN prescription_drugs on prescription_drugs.patient_id = patients.id
          AND prescription_drugs.device_created_at BETWEEN :range_start AND :range_end
        LEFT JOIN blood_sugars on blood_sugars.patient_id = patients.id
          AND blood_sugars.device_created_at BETWEEN :range_start AND :range_end
        LEFT JOIN blood_pressures on blood_pressures.patient_id = patients.id
          AND blood_pressures.device_created_at BETWEEN :range_start AND :range_end
        WHERE patients.deleted_at IS NULL
          AND mh.hypertension = :hypertension
          AND (appointments.id IS NOT NULL
            OR prescription_drugs.id IS NOT NULL
            OR blood_sugars.id IS NOT NULL
            OR blood_pressures.id IS NOT NULL)
          AND patients.id IN :candidate_ids
          AND NOT EXISTS
            (SELECT 1 FROM appointments WHERE appointments.patient_id = patients.id
               AND appointments.scheduled_date >= :start_time)
      SQL
      sql.values
    end
  end
end
