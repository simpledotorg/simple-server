SELECT DISTINCT ON (patient_id, year, month)
    blood_pressures.id AS bp_id,
    blood_pressures.patient_id AS patient_id,
    patients.registration_facility_id AS registration_facility_id,
    blood_pressures.facility_id AS bp_facility_id,
    blood_pressures.recorded_at AS bp_recorded_at,
    patients.recorded_at AS patient_recorded_at,
    blood_pressures.systolic AS systolic,
    blood_pressures.diastolic AS diastolic,
    blood_pressures.deleted_at AS deleted_at,
    cast(EXTRACT(MONTH FROM blood_pressures.recorded_at) as text) AS month,
    cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at) as text) AS quarter,
    cast(EXTRACT(YEAR FROM blood_pressures.recorded_at) as text) AS year
FROM blood_pressures JOIN patients ON patients.id = blood_pressures.patient_id
ORDER BY patient_id, year, month, blood_pressures.recorded_at DESC, bp_id;
