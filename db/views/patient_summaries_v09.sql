SELECT
  p.recorded_at,
  p.device_created_at,
  CONCAT(date_part('year', p.recorded_at), ' Q', EXTRACT(QUARTER FROM p.recorded_at)) AS registration_quarter,
  p.full_name,
  (
    CASE
      WHEN p.date_of_birth IS NOT NULL THEN date_part('year', age(p.date_of_birth))
      ELSE p.age + date_part('years', age(NOW(), p.age_updated_at))
      END
    ) AS current_age,
  p.gender,
  p.status,
  p.assigned_facility_id AS assigned_facility_id,
  latest_phone_number.number AS latest_phone_number,
  addresses.village_or_colony AS village_or_colony,
  addresses.street_address AS street_address,
  addresses.district AS district,
  addresses.state AS state,
  reg_facility.name AS registration_facility_name,
  reg_facility.facility_type AS registration_facility_type,
  reg_facility.district AS registration_district,
  reg_facility.state AS registration_state,
  latest_blood_pressure.systolic AS latest_blood_pressure_systolic,
  latest_blood_pressure.diastolic AS latest_blood_pressure_diastolic,
  latest_blood_pressure.recorded_at AS latest_blood_pressure_recorded_at,
  CONCAT(date_part('year', latest_blood_pressure.recorded_at), ' Q', EXTRACT(QUARTER FROM latest_blood_pressure.recorded_at)) AS latest_blood_pressure_quarter,
  latest_blood_pressure_facility.name AS latest_blood_pressure_facility_name,
  latest_blood_pressure_facility.facility_type AS latest_blood_pressure_facility_type,
  latest_blood_pressure_facility.district AS latest_blood_pressure_district,
  latest_blood_pressure_facility.state AS latest_blood_pressure_state,
  latest_blood_sugar.blood_sugar_type AS latest_blood_sugar_type,
  latest_blood_sugar.blood_sugar_value AS latest_blood_sugar_value,
  latest_blood_sugar.recorded_at AS latest_blood_sugar_recorded_at,
  latest_blood_sugar.device_created_at AS latest_blood_sugar_device_created_at,
  CONCAT(date_part('year', latest_blood_sugar.recorded_at), ' Q', EXTRACT(QUARTER FROM latest_blood_sugar.recorded_at)) AS latest_blood_sugar_quarter,
  latest_blood_sugar_facility.name AS latest_blood_sugar_facility_name,
  latest_blood_sugar_facility.facility_type AS latest_blood_sugar_facility_type,
  latest_blood_sugar_facility.district AS latest_blood_sugar_district,
  latest_blood_sugar_facility.state AS latest_blood_sugar_state,
  greatest(0, date_part('day', NOW() - next_appointment.scheduled_date)) AS days_overdue,
  next_appointment.id AS next_appointment_id,
  next_appointment.scheduled_date AS next_appointment_scheduled_date,
  next_appointment.status AS next_appointment_status,
  next_appointment.cancel_reason AS next_appointment_cancel_reason,
  next_appointment.remind_on AS next_appointment_remind_on,
  next_appointment_facility.id AS next_appointment_facility_id,
  next_appointment_facility.name AS next_appointment_facility_name,
  next_appointment_facility.facility_type AS next_appointment_facility_type,
  next_appointment_facility.district AS next_appointment_district,
  next_appointment_facility.state AS next_appointment_state,

  (
    CASE
      WHEN next_appointment.scheduled_date IS NULL THEN 0
      WHEN next_appointment.scheduled_date > date_trunc('day', NOW() - interval '30 days') THEN 0
      WHEN (latest_blood_pressure.systolic >= 180 OR latest_blood_pressure.diastolic >= 110) THEN 1
      WHEN (
          (mh.prior_heart_attack = 'yes' OR mh.prior_stroke = 'yes')
          AND (latest_blood_pressure.systolic >= 140 OR latest_blood_pressure.diastolic >= 90)
        ) THEN 1
      WHEN (
          (latest_blood_sugar.blood_sugar_type = 'random' AND latest_blood_sugar.blood_sugar_value >= 300)
          OR (latest_blood_sugar.blood_sugar_type = 'post_prandial' AND latest_blood_sugar.blood_sugar_value >= 300)
          OR (latest_blood_sugar.blood_sugar_type = 'fasting' AND latest_blood_sugar.blood_sugar_value >= 200)
          OR (latest_blood_sugar.blood_sugar_type = 'hba1c' AND latest_blood_sugar.blood_sugar_value >= 9.0)
        ) THEN 1
      ELSE 0
      END
    ) AS risk_level,

  latest_bp_passport.id AS latest_bp_passport_id,
  latest_bp_passport.identifier AS latest_bp_passport_identifier,

  p.id

FROM patients p

       LEFT OUTER JOIN addresses ON addresses.id = p.address_id
       LEFT OUTER JOIN facilities reg_facility ON reg_facility.id = p.registration_facility_id
       LEFT OUTER JOIN medical_histories mh ON mh.patient_id = p.id

       LEFT JOIN LATERAL (
  SELECT *
  FROM patient_phone_numbers ppn
  WHERE ppn.patient_id = p.id
  ORDER by ppn.device_created_at desc
  LIMIT 1
  ) latest_phone_number ON TRUE

       LEFT JOIN LATERAL (
  SELECT *
  FROM blood_pressures bp
  WHERE bp.patient_id = p.id
  ORDER by bp.recorded_at desc
  LIMIT 1
  ) latest_blood_pressure ON TRUE
       LEFT OUTER JOIN facilities latest_blood_pressure_facility ON latest_blood_pressure_facility.id = latest_blood_pressure.facility_id

       LEFT JOIN LATERAL (
  SELECT *
  FROM blood_sugars bs
  WHERE bs.patient_id = p.id
  ORDER by bs.recorded_at desc
  LIMIT 1
  ) latest_blood_sugar ON TRUE
       LEFT OUTER JOIN facilities latest_blood_sugar_facility ON latest_blood_sugar_facility.id = latest_blood_sugar.facility_id

       LEFT JOIN LATERAL (
  SELECT *
  FROM patient_business_identifiers bp_passport
  WHERE identifier_type = 'simple_bp_passport'
    AND bp_passport.patient_id = p.id
  ORDER by bp_passport.device_created_at desc
  LIMIT 1
  ) latest_bp_passport ON TRUE

       LEFT JOIN LATERAL (
  SELECT *
  FROM appointments a
  WHERE a.patient_id = p.id
  ORDER by a.scheduled_date DESC
  LIMIT 1
  ) next_appointment ON TRUE

       LEFT OUTER JOIN facilities next_appointment_facility ON next_appointment_facility.id = next_appointment.facility_id
WHERE p.deleted_at IS NULL;
