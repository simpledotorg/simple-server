-- Only most recent BP per patient per month. BPs are ordered appropriately below.
SELECT DISTINCT ON (bp.patient_id, cal.month_date)
    cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS blood_pressure_recorded_at,
    p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_registered_at,
    bp.id                      AS blood_pressure_id,
    bp.patient_id,
    bp.systolic,
    bp.diastolic,
    p.assigned_facility_id     AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    bp.facility_id             AS blood_pressure_facility_id,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (cal.year - DATE_PART('year', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_bp_observation

FROM blood_pressures bp
-- Only fetch BPs that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN reporting_months cal
ON to_char(bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
INNER JOIN patients p ON bp.patient_id = p.id AND p.deleted_at IS NULL
WHERE bp.deleted_at IS NULL
ORDER BY
-- Ensure most recent BP is fetched
    bp.patient_id,
    cal.month_date,
    bp.recorded_at DESC
