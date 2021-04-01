SELECT
  DISTINCT ON (patients.id, month_date)
  patients.id,
  patients.recorded_at,
  calendar_months.month,
  calendar_months.year,
  calendar_months.month_date,
  bpot.systolic,
  bpot.diastolic,
  bpot.blood_pressure_recorded_at AS bp_recorded_at,
  eot.encountered_at AS encountered_at,
  patients.assigned_facility_id AS patient_assigned_facility_id,
  patients.registration_facility_id AS patient_registration_facility_id,

  (DATE_PART('year', calendar_months.month_date) - DATE_PART('year', patients.recorded_at)) * 12 +
  (DATE_PART('month', calendar_months.month_date) - DATE_PART('month', patients.recorded_at))
    AS months_since_registration,

  CASE
    WHEN medical_histories.hypertension = 'yes' AND (bpot.systolic >= 180 OR bpot.diastolic >= 110) THEN 'Stage 3'
    WHEN medical_histories.hypertension = 'yes' AND (bpot.systolic >= 160 OR bpot.diastolic >= 100) THEN 'Stage 2'
    WHEN medical_histories.hypertension = 'yes' AND (bpot.systolic >= 140 OR bpot.diastolic >= 90) THEN 'Stage 1'
    WHEN medical_histories.hypertension = 'yes' AND (bpot.systolic < 140 AND bpot.diastolic < 90) THEN 'Controlled'
    WHEN medical_histories.hypertension = 'yes' AND (bpot.systolic IS null) THEN 'Hypertensive Unknown Stage'
    WHEN medical_histories.hypertension = 'unknown' THEN 'Unknown'
    WHEN medical_histories.hypertension = 'no' THEN 'Not hypertensive'
    ELSE 'Undefined'
  END
    AS diagnosed_disease_state,

  CASE
    WHEN patients.status = 'dead' THEN 'Not needed'
    WHEN patients.status = 'migrated' THEN 'Not needed'
    WHEN medical_histories.hypertension = 'no' THEN 'Not needed'
    WHEN eot.months_since_encounter < 3 THEN 'Less than 3 months'
    WHEN eot.months_since_encounter < 6 THEN 'Between 3 and 6 months'
    WHEN eot.months_since_encounter < 9 THEN 'Between 6 and 9 months'
    WHEN eot.months_since_encounter < 12 THEN 'Between 9 and 12 months'
    WHEN eot.months_since_encounter >= 12 THEN 'More than 12 months'
    WHEN eot.months_since_encounter IS null THEN 'No encounter'
    ELSE 'Undefined'
  END
    AS treatment_state,

  CASE
    WHEN bpot.months_since_bp_observation < 3 THEN 'Less than 3 months'
    WHEN bpot.months_since_bp_observation < 6 THEN 'Between 3 and 6 months'
    WHEN bpot.months_since_bp_observation < 9 THEN 'Between 6 and 9 months'
    WHEN bpot.months_since_bp_observation < 12 THEN 'Between 9 and 12 months'
    WHEN bpot.months_since_bp_observation >= 12 THEN 'More than 12 months'
    WHEN bpot.months_since_bp_observation IS null THEN 'No measurement'
    ELSE 'Undefined'
  END
    AS bp_observation_state
FROM
  patients

LEFT OUTER JOIN calendar_months
  ON (
    -- Only fetch BPs that happened on or before the selected calendar month
    -- We use year and month comparisons to avoid timezone errors
    EXTRACT(YEAR FROM patients.recorded_at at time zone 'utc' at time zone 'Asia/Kolkata') < calendar_months.year
    OR
    (
        EXTRACT(YEAR FROM patients.recorded_at at time zone 'utc' at time zone 'Asia/Kolkata') = calendar_months.year
        AND
        EXTRACT(MONTH FROM patients.recorded_at at time zone 'utc' at time zone 'Asia/Kolkata') <= calendar_months.month
    )
)
LEFT OUTER JOIN blood_pressures_over_time bpot
  ON patients.id = bpot.patient_id AND calendar_months.month = bpot.month AND calendar_months.year = bpot.year
LEFT OUTER JOIN encounters_over_time eot
  ON patients.id = eot.patient_id AND calendar_months.month = eot.month AND calendar_months.year = eot.year
LEFT OUTER JOIN medical_histories
  ON patients.id = medical_histories.patient_id
ORDER BY patients.id, month_date ASC
