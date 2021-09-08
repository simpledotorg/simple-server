SELECT DISTINCT ON (patient_id, year, month)
    blood_pressures.id AS bp_id,
    blood_pressures.patient_id AS patient_id,
    patients.registration_facility_id AS registration_facility_id,
    patients.assigned_facility_id AS assigned_facility_id,
    patients.status as patient_status,
    blood_pressures.facility_id AS bp_facility_id,
    blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS bp_recorded_at,
    patients.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_recorded_at,
    blood_pressures.systolic AS systolic,
    blood_pressures.diastolic AS diastolic,
    blood_pressures.deleted_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS deleted_at,
    medical_histories.hypertension as medical_history_hypertension,
    cast(EXTRACT(MONTH FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS month,
    cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
    cast(EXTRACT(YEAR FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS year
FROM blood_pressures JOIN patients ON patients.id = blood_pressures.patient_id
LEFT JOIN medical_histories ON medical_histories.patient_id = blood_pressures.patient_id
WHERE blood_pressures.deleted_at IS NULL AND patients.deleted_at IS NULL
ORDER BY patient_id, year, month, blood_pressures.recorded_at DESC, bp_id;
