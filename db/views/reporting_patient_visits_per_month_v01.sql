-- Only most recent Encounter per patient per month. Encounters are ordered appropriately below.
SELECT
    DISTINCT ON (p.id, p.month_date)
    p.id as patient_id,
    p.month_date,
    p.month_string,
    p.month,
    p.quarter,
    p.year,
    -- encountered_on is stored as a date in local time, this comparison is a bit flawed but is perhaps permissible
    greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS visited_at,
    p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    e.facility_id AS encounter_facility_id,

    (p.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (p.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (p.year - DATE_PART('year', greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (p.month - DATE_PART('month', greatest(e.encountered_on, pd.device_created_at, app.device_created_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_visit

FROM
(
    SELECT * FROM patients p
    LEFT OUTER JOIN reporting_months cal
    ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= cal.month_string
) p
-- Only fetch Encounters that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT JOIN LATERAL (
    SELECT encountered_on, facility_id
    FROM encounters
    WHERE patient_id = p.id
      AND to_char(encountered_on, 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY encountered_on DESC
    LIMIT 1
) e ON true
LEFT JOIN LATERAL (
    SELECT device_created_at
    FROM prescription_drugs
    WHERE patient_id = p.id
      AND to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY device_created_at DESC
    LIMIT 1
) pd ON true
LEFT JOIN LATERAL (
    SELECT device_created_at
    FROM appointments
    WHERE patient_id = p.id
      AND to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY device_created_at DESC
    LIMIT 1
) app ON true
-- Ensure most recent visit is fetched
WHERE p.deleted_at IS NULL
ORDER BY
    p.id,
    p.month_date,
    visited_at DESC
