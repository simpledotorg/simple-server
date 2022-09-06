SELECT p.recorded_at,
       CONCAT(date_part('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE
                                (SELECT current_setting('TIMEZONE'))), ' Q', EXTRACT(QUARTER
                                                                                     FROM p.recorded_at AT TIME ZONE
                                                                                          'UTC' AT TIME ZONE
                                                                                          (SELECT current_setting('TIMEZONE')))) AS registration_quarter,
       p.full_name,
       (CASE
            WHEN p.date_of_birth IS NOT NULL THEN date_part('year', age(p.date_of_birth))
            ELSE floor(p.age + date_part('year', age(p.age_updated_at AT TIME ZONE 'UTC' AT TIME ZONE
                                                     (SELECT current_setting('TIMEZONE')))))
           END)                                                                                                                  AS current_age,
       p.gender,
       p.status,
       latest_phone_number.number                                                                                                AS latest_phone_number,
       addresses.village_or_colony                                                                                               AS village_or_colony,
       addresses.street_address                                                                                                  AS street_address,
       addresses.district                                                                                                        AS district,
       addresses.state                                                                                                           AS state,
       addresses.zone                                                                                                            AS block,
       reg_facility.name                                                                                                         AS registration_facility_name,
       reg_facility.facility_type                                                                                                AS registration_facility_type,
       reg_facility.district                                                                                                     AS registration_district,
       reg_facility.state                                                                                                        AS registration_state,
       p.assigned_facility_id                                                                                                    AS assigned_facility_id,
       assigned_facility.name                                                                                                    AS assigned_facility_name,
       assigned_facility.facility_type                                                                                           AS assigned_facility_type,
       assigned_facility.district                                                                                                AS assigned_facility_district,
       assigned_facility.state                                                                                                   AS assigned_facility_state,
       latest_blood_pressure.systolic                                                                                            AS latest_blood_pressure_systolic,
       latest_blood_pressure.diastolic                                                                                           AS latest_blood_pressure_diastolic,
       latest_blood_pressure.recorded_at                                                                                         AS latest_blood_pressure_recorded_at,
       CONCAT(date_part('year', latest_blood_pressure.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE
                                (SELECT current_setting('TIMEZONE'))), ' Q', EXTRACT(QUARTER
                                                                                     FROM
                                                                                     latest_blood_pressure.recorded_at AT TIME ZONE
                                                                                     'UTC' AT TIME ZONE
                                                                                     (SELECT current_setting('TIMEZONE'))))      AS latest_blood_pressure_quarter,
       latest_blood_pressure_facility.name                                                                                       AS latest_blood_pressure_facility_name,
       latest_blood_pressure_facility.facility_type                                                                              AS latest_blood_pressure_facility_type,
       latest_blood_pressure_facility.district                                                                                   AS latest_blood_pressure_district,
       latest_blood_pressure_facility.state                                                                                      AS latest_blood_pressure_state,
       latest_blood_sugar.id                                                                                                     AS latest_blood_sugar_id,
       latest_blood_sugar.blood_sugar_type                                                                                       AS latest_blood_sugar_type,
       latest_blood_sugar.blood_sugar_value                                                                                      AS latest_blood_sugar_value,
       latest_blood_sugar.recorded_at                                                                                            AS latest_blood_sugar_recorded_at,
       CONCAT(date_part('year', latest_blood_sugar.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE
                                (SELECT current_setting('TIMEZONE'))), ' Q', EXTRACT(QUARTER
                                                                                     FROM
                                                                                     latest_blood_sugar.recorded_at AT TIME ZONE
                                                                                     'UTC' AT TIME ZONE
                                                                                     (SELECT current_setting('TIMEZONE'))))      AS latest_blood_sugar_quarter,
       latest_blood_sugar_facility.name                                                                                          AS latest_blood_sugar_facility_name,
       latest_blood_sugar_facility.facility_type                                                                                 AS latest_blood_sugar_facility_type,
       latest_blood_sugar_facility.district                                                                                      AS latest_blood_sugar_district,
       latest_blood_sugar_facility.state                                                                                         AS latest_blood_sugar_state,
       greatest(0,
                date_part('day', NOW() - next_scheduled_appointment.scheduled_date))                                             AS days_overdue,
       next_scheduled_appointment.id                                                                                             AS next_scheduled_appointment_id,
       next_scheduled_appointment.scheduled_date                                                                                 AS next_scheduled_appointment_scheduled_date,
       next_scheduled_appointment.status                                                                                         AS next_scheduled_appointment_status,
       next_scheduled_appointment.remind_on                                                                                      AS next_scheduled_appointment_remind_on,
       next_scheduled_appointment_facility.id                                                                                    AS next_scheduled_appointment_facility_id,
       next_scheduled_appointment_facility.name                                                                                  AS next_scheduled_appointment_facility_name,
       next_scheduled_appointment_facility.facility_type                                                                         AS next_scheduled_appointment_facility_type,
       next_scheduled_appointment_facility.district                                                                              AS next_scheduled_appointment_district,
       next_scheduled_appointment_facility.state                                                                                 AS next_scheduled_appointment_state,
       (CASE
            WHEN next_scheduled_appointment.scheduled_date IS NULL THEN 0
            WHEN next_scheduled_appointment.scheduled_date > date_trunc('day', NOW() - interval '30 days') THEN 0
            WHEN (latest_blood_pressure.systolic >= 180
                OR latest_blood_pressure.diastolic >= 110) THEN 1
            WHEN ((mh.prior_heart_attack = 'yes'
                OR mh.prior_stroke = 'yes')
                AND (latest_blood_pressure.systolic >= 140
                    OR latest_blood_pressure.diastolic >= 90)) THEN 1
            WHEN ((latest_blood_sugar.blood_sugar_type = 'random'
                AND latest_blood_sugar.blood_sugar_value >= 300)
                OR (latest_blood_sugar.blood_sugar_type = 'post_prandial'
                    AND latest_blood_sugar.blood_sugar_value >= 300)
                OR (latest_blood_sugar.blood_sugar_type = 'fasting'
                    AND latest_blood_sugar.blood_sugar_value >= 200)
                OR (latest_blood_sugar.blood_sugar_type = 'hba1c'
                    AND latest_blood_sugar.blood_sugar_value >= 9.0)) THEN 1
            ELSE 0
           END)                                                                                                                  AS risk_level,
       latest_bp_passport.id                                                                                                     AS latest_bp_passport_id,
       latest_bp_passport.identifier                                                                                             AS latest_bp_passport_identifier,
       mh.hypertension                                                                                                           AS hypertension,
       mh.diabetes                                                                                                               AS diabetes,
       p.id
FROM patients p
         LEFT OUTER JOIN addresses ON addresses.id = p.address_id
         LEFT OUTER JOIN facilities reg_facility ON reg_facility.id = p.registration_facility_id
         LEFT OUTER JOIN facilities assigned_facility ON assigned_facility.id = p.assigned_facility_id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM medical_histories
      WHERE deleted_at IS NULL) AS mh ON mh.patient_id = p.id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM patient_phone_numbers
      WHERE deleted_at IS NULL
      ORDER BY patient_id,
               device_created_at DESC) AS latest_phone_number ON latest_phone_number.patient_id = p.id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM blood_pressures
      WHERE deleted_at IS NULL
      ORDER BY patient_id,
               recorded_at DESC) AS latest_blood_pressure ON latest_blood_pressure.patient_id = p.id
         LEFT OUTER JOIN facilities latest_blood_pressure_facility
                         ON latest_blood_pressure_facility.id = latest_blood_pressure.facility_id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM blood_sugars
      WHERE deleted_at IS NULL
      ORDER BY patient_id,
               recorded_at DESC) AS latest_blood_sugar ON latest_blood_sugar.patient_id = p.id
         LEFT OUTER JOIN facilities latest_blood_sugar_facility
                         ON latest_blood_sugar_facility.id = latest_blood_sugar.facility_id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM patient_business_identifiers
      WHERE identifier_type = 'simple_bp_passport'
        AND deleted_at IS NULL
      ORDER BY patient_id,
               device_created_at DESC) AS latest_bp_passport ON latest_bp_passport.patient_id = p.id
         LEFT OUTER JOIN
     (SELECT DISTINCT ON (patient_id) *
      FROM appointments
      WHERE deleted_at IS NULL
      ORDER BY patient_id, device_created_at DESC) AS next_scheduled_appointment ON next_scheduled_appointment.patient_id = p.id
                                                                     AND next_scheduled_appointment.status = 'scheduled'
         LEFT OUTER JOIN facilities next_scheduled_appointment_facility
                         ON next_scheduled_appointment_facility.id = next_scheduled_appointment.facility_id
                         AND next_scheduled_appointment.status = 'scheduled'
WHERE p.deleted_at IS NULL;
