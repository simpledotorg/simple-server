-- Only most recent Encounter per patient per month. Encounters are ordered appropriately below.
SELECT
    DISTINCT ON (p.id, p.month_date)
    p.id as patient_id,

    p.month_date,
    p.month,
    p.quarter,
    p.year,
    p.month_string,
    p.quarter_string,

    p.assigned_facility_id AS assigned_facility_id,
    p.registration_facility_id AS registration_facility_id,
    p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_recorded_at,

    ------------------------------------------------------------
    -- details of the visit: latest encounter, prescription drug and appointment

    bp.id AS bp_id,
    bp.facility_id AS bp_facility_id,
    bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS bp_recorded_at,
    bp.systolic as systolic,
    bp.diastolic as diastolic,

    bs.id AS bs_id,
    bs.facility_id AS bs_facility_id,
    bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS bs_recorded_at,
    bs.blood_sugar_value as blood_sugar_value,
    bs.blood_sugar_type as blood_sugar_type,

    pd.id AS prescription_drug_id,
    pd.facility_id AS prescription_drug_facility_id,
    pd.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS prescription_drug_recorded_at,

    app.id AS appointment_id,
    app.creation_facility_id AS appointment_creation_facility_id,
    app.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS appointment_recorded_at,

    array_remove(
        ARRAY[
            (CASE WHEN to_char(bp.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') = month_string THEN bp.facility_id END),
            (CASE WHEN to_char(bs.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') = month_string THEN bs.facility_id END),
            (CASE WHEN to_char(pd.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') = month_string THEN pd.facility_id END),
            (CASE WHEN to_char(app.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') = month_string THEN app.creation_facility_id END)
        ],
        null
    ) AS visited_facility_ids,

    ------------------------------------------------------------
    -- when the visit happened
    greatest(bp.recorded_at, bs.recorded_at, pd.recorded_at, app.recorded_at) AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS visited_at,

    (p.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (p.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (p.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (p.quarter - DATE_PART('quarter', p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS quarters_since_registration,

    (p.year - DATE_PART('year', greatest(bp.recorded_at, bs.recorded_at, pd.recorded_at, app.recorded_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (p.month - DATE_PART('month', greatest(bp.recorded_at, bs.recorded_at, pd.recorded_at, app.recorded_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_visit,

    (p.year - DATE_PART('year', greatest(bp.recorded_at, bs.recorded_at, pd.recorded_at, app.recorded_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (p.quarter - DATE_PART('quarter', greatest(bp.recorded_at, bs.recorded_at, pd.recorded_at, app.recorded_at) AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS quarters_since_visit,

    (cal.year - DATE_PART('year', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_bp,

    (cal.year - DATE_PART('year', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (cal.quarter - DATE_PART('quarter', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS quarters_since_bp,

    (cal.year - DATE_PART('year', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_bs,

    (cal.year - DATE_PART('year', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (cal.quarter - DATE_PART('quarter', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS quarters_since_bs

FROM
(
    SELECT * FROM patients p
    LEFT OUTER JOIN reporting_months cal
    ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= cal.month_string
) p
-- Only fetch Encounters that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT JOIN LATERAL (
    SELECT *
    FROM blood_sugars
    WHERE patient_id = p.id
      AND to_char(recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY recorded_at DESC
    LIMIT 1
) bs ON true
LEFT JOIN LATERAL (
    SELECT *
    FROM blood_pressures
    WHERE patient_id = p.id
      AND to_char(recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY recorded_at DESC
    LIMIT 1
) bp ON true
LEFT JOIN LATERAL (
    SELECT device_created_at AS recorded_at, *
    FROM prescription_drugs
    WHERE patient_id = p.id
      AND to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
    ORDER BY device_created_at DESC
    LIMIT 1
) pd ON true
LEFT JOIN LATERAL (
    SELECT device_created_at AS recorded_at, *
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
