WITH registered_patients AS (
    SELECT DISTINCT id,
        registration_facility_id,
        assigned_facility_id,
        status,
        recorded_at
    FROM public.patients
    WHERE deleted_at IS NULL
    AND diagnosed_confirmed_at IS NOT NULL
)
SELECT DISTINCT ON (blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at)))::text), (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at)))::text)) 
    blood_pressures.id AS bp_id,
    blood_pressures.patient_id AS patient_id,
    registered_patients.registration_facility_id AS registration_facility_id,
    registered_patients.assigned_facility_id AS assigned_facility_id,
    registered_patients.status as patient_status,
    blood_pressures.facility_id AS bp_facility_id,
    timezone('UTC'::text, timezone('UTC'::text, blood_pressures.recorded_at)) AS bp_recorded_at,
    timezone('UTC'::text, timezone('UTC'::text, registered_patients.recorded_at)) AS patient_recorded_at,
    blood_pressures.systolic AS systolic,
    blood_pressures.diastolic AS diastolic,
    timezone('UTC'::text, timezone('UTC'::text, blood_pressures.deleted_at)) AS deleted_at,
    medical_histories.hypertension as medical_history_hypertension,
    date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at)))::text AS month,
    date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at)))::text AS quarter,
    date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, blood_pressures.recorded_at)))::text AS year
FROM public.blood_pressures JOIN registered_patients ON registered_patients.id = blood_pressures.patient_id
LEFT JOIN public.medical_histories ON medical_histories.patient_id = blood_pressures.patient_id
WHERE blood_pressures.deleted_at IS NULL
ORDER BY patient_id, year, month, blood_pressures.recorded_at DESC, bp_id;