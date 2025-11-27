SELECT DISTINCT ON (bp.patient_id, cal.month_date) cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,
    timezone('UTC'::text, timezone('UTC'::text, bp.recorded_at)) AS blood_pressure_recorded_at,
    bp.id AS blood_pressure_id,
    bp.patient_id,
    bp.systolic,
    bp.diastolic,
    bp.facility_id AS blood_pressure_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, p.diagnosed_confirmed_at)) AS patient_registered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at))))) AS months_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at))))) AS quarters_since_registration,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS months_since_bp,
    (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))))) AS quarters_since_bp
FROM ((public.blood_pressures bp
LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
JOIN public.patients p ON (((bp.patient_id = p.id) AND (p.deleted_at IS NULL) AND (p.diagnosed_confirmed_at IS NOT NULL))))
WHERE (bp.deleted_at IS NULL)
ORDER BY bp.patient_id, cal.month_date, bp.recorded_at DESC;