-- Only most recent BP per patient per month. BPs are ordered appropriately below.
SELECT DISTINCT ON (bp.patient_id, cal.month_date)
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    bp.recorded_at             AS blood_pressure_recorded_at,
    p.recorded_at              AS patient_registered_at,
    bp.id                      AS blood_pressure_id,
    bp.patient_id,
    bp.systolic,
    bp.diastolic,
    p.assigned_facility_id     AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    bp.facility_id             AS blood_pressure_facility_id,

    date_part('year', age(p.recorded_at, cal.month_date)) * 12 +
    date_part('month', age(p.recorded_at, cal.month_date))
    AS months_since_registration,

    date_part('year', age(bp.recorded_at, cal.month_date)) * 12 +
    date_part('month', age(bp.recorded_at, cal.month_date))
    AS months_since_bp_observation

FROM blood_pressures bp
-- Only fetch BPs that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN calendar_months cal
ON to_char(bp.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
INNER JOIN patients p ON bp.patient_id = p.id
ORDER BY
-- Ensure most recent BP is fetched
    bp.patient_id,
    cal.month_date,
    bp.recorded_at DESC