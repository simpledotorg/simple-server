WITH last_bps_per_patient_per_quarter AS (
    SELECT DISTINCT ON (patient_id, visited_in_quarter, visited_in_year)
        EXTRACT(QUARTER FROM blood_pressures.recorded_at) AS visited_in_quarter,
        EXTRACT(YEAR FROM blood_pressures.recorded_at) AS visited_in_year,
        patient_id, facility_id, recorded_at, systolic, diastolic
    FROM blood_pressures
    ORDER BY patient_id,  visited_in_year, visited_in_quarter, recorded_at DESC)
SELECT blood_pressures.facility_id,
       cast(visited_in_quarter as text),
       cast(visited_in_year as text),
       COUNT(*) AS count
FROM last_bps_per_patient_per_quarter AS blood_pressures
INNER JOIN patients ON patients.id = blood_pressures.patient_id
WHERE patients.deleted_at IS NULL AND
      (blood_pressures.systolic < 140 AND blood_pressures.diastolic < 90) AND
      (date_trunc('quarter', blood_pressures.recorded_at) = date_trunc('quarter', patients.recorded_at) + (interval '3 months'))
GROUP BY blood_pressures.facility_id, visited_in_quarter, visited_in_year;
