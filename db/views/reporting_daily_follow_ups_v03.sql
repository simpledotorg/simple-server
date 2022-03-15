WITH follow_up_blood_pressures AS (
  SELECT DISTINCT ON (patient_id, facility_id, day_of_year)
    p.id AS patient_id,
    p.gender::gender_enum as patient_gender,
    bp.id as visit_id,
    'BloodPressure' AS visit_type,
    bp.facility_id,
    bp.user_id,
    bp.recorded_at AS visited_at,
    cast(EXTRACT(DOY FROM bp.recorded_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
 FROM patients p
    INNER JOIN blood_pressures bp
      ON p.id = bp.patient_id
      AND date_trunc('day', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
        > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
  WHERE p.deleted_at IS NULL
    AND bp.recorded_at > current_timestamp - interval '30 day'
),
follow_up_blood_sugars AS (
  SELECT DISTINCT ON (patient_id, facility_id, day_of_year)
    p.id AS patient_id,
    p.gender::gender_enum as patient_gender,
    bs.id as visit_id,
   'BloodSugar' AS visit_type,
    bs.facility_id,
    bs.user_id,
    bs.recorded_at AS visited_at,
    cast(EXTRACT(DOY FROM bs.recorded_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year

  FROM patients p
  INNER JOIN blood_sugars bs
    ON p.id = bs.patient_id
    AND date_trunc('day', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
  WHERE p.deleted_at IS NULL
    AND bs.recorded_at > current_timestamp - interval '30 day'
),
follow_up_prescription_drugs AS (
  SELECT DISTINCT ON (patient_id, facility_id, day_of_year)
    p.id AS patient_id,
    p.gender::gender_enum as patient_gender,
    pd.id as visit_id,
    'PrescriptionDrug' AS visit_type,
    pd.facility_id,
    pd.user_id,
    pd.device_created_at AS visited_at,
    cast(EXTRACT(DOY FROM pd.device_created_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
  FROM patients p
  INNER JOIN prescription_drugs pd
    ON p.id = pd.patient_id
    AND date_trunc('day', pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
  WHERE p.deleted_at IS NULL
    AND pd.device_created_at > current_timestamp - interval '30 day'
),
follow_up_appointments AS (
  SELECT DISTINCT ON (patient_id, facility_id, day_of_year)
    p.id AS patient_id,
    p.gender::gender_enum as patient_gender,
    app.id as visit_id,
    'Appointment' AS visit_type,
    app.creation_facility_id AS facility_id,
    app.user_id,
    app.device_created_at as visited_at,
    cast(EXTRACT(DOY FROM app.device_created_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
FROM patients p
  INNER JOIN appointments app
    ON p.id = app.patient_id
    AND date_trunc('day', app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
  WHERE p.deleted_at IS NULL
    AND app.device_created_at > current_timestamp - interval '30 day'
),
all_follow_ups AS (
  SELECT *
  FROM
    follow_up_blood_pressures
    UNION (select * FROM follow_up_blood_sugars)
    UNION (select * FROM follow_up_prescription_drugs)
    UNION (select * FROM follow_up_appointments)
)
SELECT DISTINCT ON (all_follow_ups.day_of_year, all_follow_ups.facility_id, all_follow_ups.patient_id)
  all_follow_ups.patient_id,
  all_follow_ups.patient_gender,
  all_follow_ups.facility_id,
  mh.diabetes,
  mh.hypertension,
  all_follow_ups.user_id,
  all_follow_ups.visit_id,
  all_follow_ups.visit_type,
  all_follow_ups.visited_at,
  all_follow_ups.day_of_year
FROM
  all_follow_ups
  INNER JOIN medical_histories mh
     ON all_follow_ups.patient_id = mh.patient_id
