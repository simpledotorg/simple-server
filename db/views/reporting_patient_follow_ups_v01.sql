WITH
follow_up_blood_pressures AS (
  SELECT DISTINCT ON (patient_id, facility_id, user_id, month_string)
    p.id AS patient_id,
    bp.facility_id,
    bp.user_id,
    to_char(bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM patients p
  INNER JOIN blood_pressures bp
    ON p.id = bp.patient_id
    -- removing bps that were recorded the same month as registration
    AND to_char(bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
      > to_char(p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
),

follow_up_blood_sugars AS (
  SELECT DISTINCT ON (patient_id, facility_id, user_id, month_string)
    p.id AS patient_id,
    bs.facility_id,
    bs.user_id,
    to_char(bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM patients p
  INNER JOIN blood_sugars bs
    ON p.id = bs.patient_id
    -- removing rows that were recorded the same month as registration
    AND to_char(bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
      > to_char(p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
),

follow_up_prescription_drugs AS (
  SELECT DISTINCT ON (patient_id, facility_id, user_id, month_string)
    p.id AS patient_id,
    pd.facility_id,
    pd.user_id,
    to_char(pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM patients p
  INNER JOIN prescription_drugs pd
    ON p.id = pd.patient_id
    -- removing rows that were recorded the same month as registration
    AND to_char(pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
      > to_char(p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
),

follow_up_appointments AS (
  SELECT DISTINCT ON (patient_id, facility_id, user_id, month_string)
    p.id AS patient_id,
    app.creation_facility_id AS facility_id,
    app.user_id,
    to_char(app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') AS month_string
  FROM patients p
  INNER JOIN appointments app
    ON p.id = app.patient_id
    -- removing rows that were recorded the same month as registration
    AND to_char(app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
      > to_char(p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM')
),

all_follow_ups AS (
  SELECT *
  FROM follow_up_blood_pressures
  -- Follow-ups only look for BPs. Consider including more criteria in v2:
  -- -------
  -- UNION (SELECT * FROM follow_up_blood_sugars)
  -- UNION (SELECT * FROM follow_up_prescription_drugs)
  -- UNION (SELECT * FROM follow_up_appointments)
)

SELECT
  all_follow_ups.patient_id,
  all_follow_ups.facility_id,
  all_follow_ups.user_id,
  cal.*
FROM all_follow_ups
LEFT OUTER JOIN reporting_months cal
    ON all_follow_ups.month_string = cal.month_string
