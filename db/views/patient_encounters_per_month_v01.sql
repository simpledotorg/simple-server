-- Only most recent Encounter per patient per month. Encounters are ordered appropriately below.
SELECT
    DISTINCT ON (e.patient_id, cal.month_date)
    cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    e.encountered_on AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')) AS encountered_at,
    p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')) AS patient_registered_at,
    e.id AS encounter_id,
    e.patient_id,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    e.facility_id AS encounter_facility_id,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (cal.year - DATE_PART('year', e.encountered_on AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', e.encountered_on AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_encounter

FROM encounters e
-- Only fetch Encounters that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN calendar_months cal
    ON to_char(e.encountered_on AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
INNER JOIN patients p
    ON e.patient_id = p.id
-- Ensure most recent Encounter is fetched
ORDER BY
    e.patient_id,
    cal.month_date,
    e.encountered_on DESC