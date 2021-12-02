WITH follow_up_blood_pressures AS (
  SELECT DISTINCT ON (patient_id,
    facility_id,
    user_id,
    month_string)
    p.id AS patient_id,
    bp.id as visit_id,
    'BloodPressure' AS visit_type,
    bp.facility_id,
    bp.user_id,
    bp.recorded_at AS visit_at,
    to_char(bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM
    patients p
    INNER JOIN blood_pressures bp ON p.id = bp.patient_id
    -- removing bps that were recorded the same month as registration
      AND date_trunc('month', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
          SELECT
            current_setting('TIMEZONE'))) > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
          SELECT
            current_setting('TIMEZONE')))
),
follow_up_blood_sugars AS (
  SELECT DISTINCT ON (patient_id,
    facility_id,
    user_id,
    month_string)
    p.id AS patient_id,
    bs.id as visit_id,
   'BloodSugar' AS visit_type,
    bs.facility_id,
    bs.user_id,
    bs.recorded_at AS visit_at,
    to_char(bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
FROM
  patients p
  INNER JOIN blood_sugars bs ON p.id = bs.patient_id
  -- removing rows that were recorded the same month as registration
    AND date_trunc('month', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE'))) > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')))
),
follow_up_prescription_drugs AS (
  SELECT DISTINCT ON (patient_id,
    facility_id,
    user_id,
    month_string)
    p.id AS patient_id,
    pd.id as visit_id,
    'PrescriptionDrug' AS visit_type,
    pd.facility_id,
    pd.user_id,
    pd.device_created_at AS visit_at,
    to_char(pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM
    patients p
  INNER JOIN prescription_drugs pd ON p.id = pd.patient_id
  -- removing rows that were recorded the same month as registration
    AND date_trunc('month', pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE'))) > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')))
),
follow_up_appointments AS (
  SELECT DISTINCT ON (patient_id,
    facility_id,
    user_id,
    month_string)
    p.id AS patient_id,
    app.id as visit_id,
    'Appointment' AS visit_type,
    app.creation_facility_id AS facility_id,
    app.user_id,
    app.device_created_at as visit_at,
    to_char(app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
FROM
  patients p
  INNER JOIN appointments app ON p.id = app.patient_id
  -- removing rows that were recorded the same month as registration
    AND date_trunc('month', app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE'))) > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT
          current_setting('TIMEZONE')))
),
all_follow_ups AS (
  SELECT *
  FROM
    follow_up_blood_pressures
    UNION (select * FROM follow_up_blood_sugars)
    UNION (select * FROM follow_up_prescription_drugs)
    UNION (select * FROM follow_up_appointments)
)
SELECT
  all_follow_ups.patient_id,
  all_follow_ups.facility_id,
  all_follow_ups.user_id,
  all_follow_ups.visit_id,
  all_follow_ups.visit_type,
  all_follow_ups.visit_at,
  cal.*
FROM
  all_follow_ups
  LEFT OUTER JOIN reporting_months cal ON all_follow_ups.month_string = cal.month_string
WHERE
 facility_id = '69f27d8e-9753-4df6-80c6-8c7d3bcbd236'
 AND patient_id = '0bab9120-419a-4dd6-b919-a44f76ecb3c9'

