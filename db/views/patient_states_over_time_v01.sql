SELECT
    DISTINCT ON (p.id, month_date)
    p.id,
    p.recorded_at,
    p.deleted_at,
    p.status,
    cal.month,
    cal.year,
    cal.month_date,
    bpot.systolic,
    bpot.diastolic,
    mh.hypertension as hypertension,
    bpot.blood_pressure_recorded_at AS bp_recorded_at,
    eot.encountered_at AS encountered_at,
    p.assigned_facility_id AS patient_assigned_facility_id,
    p.registration_facility_id AS patient_registration_facility_id,

    (DATE_PART('year', cal.month_date) - DATE_PART('year', p.recorded_at)) * 12 +
    (DATE_PART('month', cal.month_date) - DATE_PART('month', p.recorded_at))
    AS months_since_registration,

    CASE
        WHEN mh.hypertension = 'yes' AND (bpot.systolic >= 180 OR bpot.diastolic >= 110) THEN 'Stage 3'
        WHEN mh.hypertension = 'yes' AND (bpot.systolic >= 160 OR bpot.diastolic >= 100) THEN 'Stage 2'
        WHEN mh.hypertension = 'yes' AND (bpot.systolic >= 140 OR bpot.diastolic >= 90) THEN 'Stage 1'
        WHEN mh.hypertension = 'yes' AND (bpot.systolic < 140 AND bpot.diastolic < 90) THEN 'Controlled'
        WHEN mh.hypertension = 'yes' AND (bpot.systolic IS null) THEN 'Hypertensive Unknown Stage'
        WHEN mh.hypertension = 'unknown' THEN 'Unknown'
        WHEN mh.hypertension = 'no' THEN 'Not hypertensive'
        ELSE 'Undefined'
        END
        AS diagnosed_disease_state,

    CASE
        WHEN p.status = 'dead' THEN 'Not needed'
        WHEN p.status = 'migrated' THEN 'Not needed'
        WHEN mh.hypertension = 'no' THEN 'Not needed'
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
        AS bp_observation_state,

    (
      (DATE_PART('year', cal.month_date) - DATE_PART('year', p.recorded_at)) * 12 +
      (DATE_PART('month', cal.month_date) - DATE_PART('month', p.recorded_at)) >= 12

      AND (bpot.months_since_bp_observation IS NULL OR bpot.months_since_bp_observation >= 12)
      AND mh.hypertension = 'yes'
      AND p.status <> 'dead'
      AND p.deleted_at IS NULL
    ) AS lost_to_follow_up

FROM patients p
-- Only fetch BPs that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN calendar_months cal
    ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')
LEFT OUTER JOIN blood_pressures_over_time bpot
    ON p.id = bpot.patient_id AND cal.month = bpot.month AND cal.year = bpot.year
LEFT OUTER JOIN encounters_over_time eot
    ON p.id = eot.patient_id AND cal.month = eot.month AND cal.year = eot.year
LEFT OUTER JOIN medical_histories mh
    ON p.id = mh.patient_id
ORDER BY
    p.id,
    cal.month_date ASC
