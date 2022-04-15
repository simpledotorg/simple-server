-- Only most recent BS per patient per month. BSs are ordered appropriately below.
SELECT DISTINCT ON (bs.patient_id, cal.month_date)
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,

    ------------------------------------------------------------
    -- Information about the latest BS as of a given month
    bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS blood_sugar_recorded_at,
    bs.id AS blood_sugar_id,
    bs.patient_id,
    bs.blood_sugar_type,
    bs.blood_sugar_value,
    bs.facility_id AS blood_sugar_facility_id,

    ------------------------------------------------------------
    -- Risk state of the latest measurement as of given month
    -- +----------+--------------+------------------+-------------+
    -- |   Type   | bs-below-200 |  bs-200-to-299   | bs-over-299 |
    -- +----------+--------------+------------------+-------------+
    -- | RBS/PPBS | bs < 200     | 200 <= bs <= 299 | bs > 299    |
    -- | FBS      | bs < 126     | 126 <= bs <= 199 | bs > 199    |
    -- | Hba1c    | bs < 7.0     | 7.0 <= bs < 9.0  | bs >= 9.0   |
    -- +----------+--------------+------------------+-------------+
    CASE
        -- RBS/PPBS
        WHEN bs.blood_sugar_type = 'random' or blood_sugar_type = 'post_prandial' THEN
            CASE
                WHEN bs.blood_sugar_value < 200.0 THEN 'bs_below_200'
                WHEN bs.blood_sugar_value >= 200.0 AND bs.blood_sugar_value < 300.0 THEN 'bs_200_to_300'
                WHEN bs.blood_sugar_value >= 300.0 THEN 'bs_over_300'
                END

        -- FBS
        WHEN bs.blood_sugar_type = 'fasting' THEN
            CASE
                WHEN bs.blood_sugar_value < 126.0 THEN 'bs_below_200'
                WHEN bs.blood_sugar_value >= 126.0 AND bs.blood_sugar_value < 200.0 THEN 'bs_200_to_300'
                WHEN bs.blood_sugar_value >= 200.0 THEN 'bs_over_300'
                END

        -- Hba1c
        WHEN bs.blood_sugar_type = 'hba1c' THEN
            CASE
                WHEN bs.blood_sugar_value < 7.0 THEN 'bs_below_200'
                WHEN bs.blood_sugar_value >= 7.0 AND bs.blood_sugar_value < 9.0 THEN 'bs_200_to_300'
                WHEN bs.blood_sugar_value >= 9.0 THEN 'bs_over_300'
                END
        END
        AS blood_sugar_risk_state,

    ------------------------------------------------------------
    -- patient information
    p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
                                                         AS months_since_registration,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (cal.quarter - DATE_PART('quarter', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
                                                         AS quarters_since_registration,

    (cal.year - DATE_PART('year', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
                                                         AS months_since_bs,

    (cal.year - DATE_PART('year', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (cal.quarter - DATE_PART('quarter', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
                                                         AS quarters_since_bs

FROM blood_sugars bs
         -- Only fetch BSs that happened on or before the selected calendar month
         -- We use year and month comparisons to avoid timezone errors
         LEFT OUTER JOIN reporting_months cal
                         ON to_char(bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
         INNER JOIN patients p ON bs.patient_id = p.id AND p.deleted_at IS NULL
WHERE bs.deleted_at IS NULL
ORDER BY
-- Ensure most recent BP is fetched
bs.patient_id,
cal.month_date,
bs.recorded_at DESC