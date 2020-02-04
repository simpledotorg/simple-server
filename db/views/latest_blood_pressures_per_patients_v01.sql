SELECT DISTINCT ON (patient_id) *
FROM latest_blood_pressures_per_patient_per_months
ORDER BY patient_id, bp_recorded_at DESC, bp_id;
