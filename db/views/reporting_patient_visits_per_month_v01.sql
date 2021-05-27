-- Only most recent Encounter per patient per month. Encounters are ordered appropriately below.
SELECT
    DISTINCT ON (p.id, cal.month_date)
    p.id as patient_id,
    cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')) AS visited_at,
    p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')) AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    e.facility_id AS encounter_facility_id,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (cal.year - DATE_PART('year', greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_visit

FROM patients p
LEFT OUTER JOIN reporting_calendar_months cal
    ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
-- Only fetch Encounters that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN encounters e
    ON e.patient_id = p.id
    AND to_char(e.encountered_on AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
LEFT OUTER JOIN prescription_drugs pd
    ON pd.patient_id = p.id
    AND to_char(pd.device_created_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
LEFT OUTER JOIN appointments app
    ON app.patient_id = p.id
    AND to_char(app.device_created_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
-- Ensure most recent visit is fetched
ORDER BY
    p.id,
    cal.month_date,
    visited_at DESC