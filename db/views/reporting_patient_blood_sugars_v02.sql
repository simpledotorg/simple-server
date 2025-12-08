-- Only most recent BS per patient per month. BSs are ordered appropriately below.
SELECT DISTINCT ON (bs.patient_id, cal.month_date) cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    timezone('UTC'::text, timezone('UTC'::text, bs.recorded_at)) AS blood_sugar_recorded_at,
    bs.id AS blood_sugar_id,
    bs.patient_id,
    bs.blood_sugar_type,
    bs.blood_sugar_value,
    bs.facility_id AS blood_sugar_facility_id,
        CASE
            WHEN (((bs.blood_sugar_type)::text = 'random'::text) OR ((bs.blood_sugar_type)::text = 'post_prandial'::text)) THEN
            CASE
                WHEN (bs.blood_sugar_value < 200.0) THEN 'bs_below_200'::text
                WHEN ((bs.blood_sugar_value >= 200.0) AND (bs.blood_sugar_value < 300.0)) THEN 'bs_200_to_300'::text
                WHEN (bs.blood_sugar_value >= 300.0) THEN 'bs_over_300'::text
                ELSE NULL::text
            END
            WHEN ((bs.blood_sugar_type)::text = 'fasting'::text) THEN
            CASE
                WHEN (bs.blood_sugar_value < 126.0) THEN 'bs_below_200'::text
                WHEN ((bs.blood_sugar_value >= 126.0) AND (bs.blood_sugar_value < 200.0)) THEN 'bs_200_to_300'::text
                WHEN (bs.blood_sugar_value >= 200.0) THEN 'bs_over_300'::text
                ELSE NULL::text
            END
            WHEN ((bs.blood_sugar_type)::text = 'hba1c'::text) THEN
            CASE
                WHEN (bs.blood_sugar_value < 7.0) THEN 'bs_below_200'::text
                WHEN ((bs.blood_sugar_value >= 7.0) AND (bs.blood_sugar_value < 9.0)) THEN 'bs_200_to_300'::text
                WHEN (bs.blood_sugar_value >= 9.0) THEN 'bs_over_300'::text
                ELSE NULL::text
            END
            ELSE NULL::text
        END AS blood_sugar_risk_state,
    timezone('UTC'::text, timezone('UTC'::text, p.diagnosed_confirmed_at)) AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at))))) AS months_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at))))) AS quarters_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))))) AS months_since_bs,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))))) AS quarters_since_bs
   FROM ((public.blood_sugars bs
     LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
     JOIN public.patients p ON (((bs.patient_id = p.id) AND (p.deleted_at IS NULL) AND (p.diagnosed_confirmed_at IS NOT NULL))))
  WHERE (bs.deleted_at IS NULL)
  ORDER BY bs.patient_id, cal.month_date, bs.recorded_at DESC;