WITH latest_bp_per_patient_per_quarter AS (
    SELECT DISTINCT ON (patient_id, year, quarter) *
    FROM latest_blood_pressures_per_patient_per_months
    ORDER BY patient_id, year, quarter, bp_recorded_at DESC, bp_id
)
SELECT bp_id,
       patient_id,
       registration_facility_id,
       bp_facility_id,
       bp_recorded_at,
       patient_recorded_at,
       systolic,
       diastolic,
       deleted_at,
       month,
       quarter,
       year,
       LAG(bp_facility_id, 1) OVER (PARTITION BY patient_id ORDER BY bp_recorded_at ASC, bp_id) AS responsible_facility_id
FROM latest_bp_per_patient_per_quarter;
