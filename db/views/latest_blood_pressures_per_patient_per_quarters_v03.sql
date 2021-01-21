SELECT DISTINCT ON (patient_id, year, quarter) *
FROM latest_blood_pressures_per_patient_per_months
ORDER BY patient_id, year, quarter, bp_recorded_at DESC, bp_id;
