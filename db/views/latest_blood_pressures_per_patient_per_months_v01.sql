SELECT DISTINCT ON (patient_id, year, month)
    id, patient_id, facility_id, recorded_at, systolic, diastolic, deleted_at,
    cast(EXTRACT(MONTH FROM blood_pressures.recorded_at) as text) AS month,
    cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at) as text) AS quarter,
    cast(EXTRACT(YEAR FROM blood_pressures.recorded_at) as text) AS year
FROM blood_pressures
ORDER BY patient_id, year, month, recorded_at DESC, id;