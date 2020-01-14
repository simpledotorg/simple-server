SELECT DISTINCT ON (patient_id, year, month)
    blood_pressures.id, patient_id, patients.registration_facility_id, facility_id,
    blood_pressures.recorded_at, systolic, diastolic, blood_pressures.deleted_at,
    cast(EXTRACT(MONTH FROM blood_pressures.recorded_at) as text) AS month,
    cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at) as text) AS quarter,
    cast(EXTRACT(YEAR FROM blood_pressures.recorded_at) as text) AS year
FROM blood_pressures JOIN patients ON patients.id = blood_pressures.patient_id
ORDER BY patient_id, year, month, recorded_at DESC, id;