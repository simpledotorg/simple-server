SELECT
    DISTINCT ON (p.id, month_date)
    ------------------------------------------------------------
    -- basic patient identifiers
    p.id as patient_id,
    p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' as recorded_at,
    p.status,
    p.gender,
    p.age,
    p.age_updated_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS age_updated_at,
    p.date_of_birth,
    EXTRACT(YEAR
        FROM COALESCE(
            age(p.date_of_birth),
            make_interval(years => p.age) + age(p.age_updated_at)
        )
    ) AS current_age,

    ------------------------------------------------------------
    -- data for the month of
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string,

    ------------------------------------------------------------
    -- medical history
    mh.hypertension as hypertension,
    mh.prior_heart_attack as prior_heart_attack,
    mh.prior_stroke as prior_stroke,
    mh.chronic_kidney_disease as chronic_kidney_disease,
    mh.receiving_treatment_for_hypertension as receiving_treatment_for_hypertension,
    mh.diabetes as diabetes,

    ------------------------------------------------------------
    -- information on assigned facility and parent regions
    p.assigned_facility_id AS assigned_facility_id,
    assigned_facility.facility_size as assigned_facility_size,
    assigned_facility.facility_type as assigned_facility_type,
    assigned_facility.facility_region_slug as assigned_facility_slug,
    assigned_facility.facility_region_id as assigned_facility_region_id,
    assigned_facility.block_slug as assigned_block_slug,
    assigned_facility.block_region_id as assigned_block_region_id,
    assigned_facility.district_slug as assigned_district_slug,
    assigned_facility.district_region_id as assigned_district_region_id,
    assigned_facility.state_slug as assigned_state_slug,
    assigned_facility.state_region_id as assigned_state_region_id,
    assigned_facility.organization_slug as assigned_organization_slug,
    assigned_facility.organization_region_id as assigned_organization_region_id,

    ------------------------------------------------------------
    -- information on registration facility and parent regions
    p.registration_facility_id AS registration_facility_id,
    registration_facility.facility_size as registration_facility_size,
    registration_facility.facility_type as registration_facility_type,
    registration_facility.facility_region_slug as registration_facility_slug,
    registration_facility.facility_region_id as registration_facility_region_id,
    registration_facility.block_slug as registration_block_slug,
    registration_facility.block_region_id as registration_block_region_id,
    registration_facility.district_slug as registration_district_slug,
    registration_facility.district_region_id as registration_district_region_id,
    registration_facility.state_slug as registration_state_slug,
    registration_facility.state_region_id as registration_state_region_id,
    registration_facility.organization_slug as registration_organization_slug,
    registration_facility.organization_region_id as registration_organization_region_id,

    ------------------------------------------------------------
    -- details of the visit: latest BP, encounter, prescription drug and appointment
    bps.blood_pressure_id as blood_pressure_id,
    bps.blood_pressure_facility_id AS bp_facility_id,
    bps.blood_pressure_recorded_at AS bp_recorded_at,
    bps.systolic,
    bps.diastolic,

    visits.encounter_id AS encounter_id,
    visits.encounter_recorded_at AS encounter_recorded_at,

    visits.prescription_drug_id AS prescription_drug_id,
    visits.prescription_drug_recorded_at AS prescription_drug_recorded_at,

    visits.appointment_id AS appointment_id,
    visits.appointment_recorded_at AS appointment_recorded_at,

    visits.visited_facility_ids as visited_facility_ids,
    ------------------------------------------------------------
    -- relative time calculations

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
    (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS months_since_registration,

    (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
    (cal.month - DATE_PART('quarter', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
    AS quarters_since_registration,

    visits.months_since_visit AS months_since_visit,
    visits.quarters_since_visit AS quarters_since_visit,
    bps.months_since_bp AS months_since_bp,
    bps.quarters_since_bp AS quarters_since_bp,

    ------------------------------------------------------------
    -- indicators
    CASE
        WHEN (bps.systolic IS NULL OR bps.diastolic IS NULL) THEN 'unknown'
        WHEN (bps.systolic < 140 AND bps.diastolic < 90) THEN 'controlled'
        ELSE 'uncontrolled'
        END
        AS last_bp_state,

    CASE
        WHEN p.status = 'dead' THEN 'dead'
        WHEN (
          -- months_since_registration
          (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
          (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) < 12

          OR

          bps.months_since_bp < 12
        ) THEN 'under_care'
        ELSE 'lost_to_follow_up'
        END
        AS htn_care_state,

    CASE
        WHEN (visits.months_since_visit >= 3 OR visits.months_since_visit is NULL) THEN 'missed_visit'
        WHEN (bps.months_since_bp >= 3 OR bps.months_since_bp is NULL) THEN 'visited_no_bp'
        WHEN (bps.systolic < 140 AND bps.diastolic < 90) THEN 'controlled'
        ELSE 'uncontrolled'
        END
        AS htn_treatment_outcome_in_last_3_months,

    CASE
        WHEN (visits.months_since_visit >= 2 OR visits.months_since_visit is NULL) THEN 'missed_visit'
        WHEN (bps.months_since_bp >= 2 OR bps.months_since_bp is NULL) THEN 'visited_no_bp'
        WHEN (bps.systolic < 140 AND bps.diastolic < 90) THEN 'controlled'
        ELSE 'uncontrolled'
        END
        AS htn_treatment_outcome_in_last_2_months,

    CASE
        WHEN (visits.quarters_since_visit >= 1 OR visits.quarters_since_visit is NULL) THEN 'missed_visit'
        WHEN (bps.quarters_since_bp >= 1 OR bps.quarters_since_bp is NULL) THEN 'visited_no_bp'
        WHEN (bps.systolic < 140 AND bps.diastolic < 90) THEN 'controlled'
        ELSE 'uncontrolled'
        END
        AS htn_treatment_outcome_in_quarter

FROM patients p
LEFT OUTER JOIN reporting_months cal
    ON to_char(p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= to_char(cal.month_date, 'YYYY-MM')

-- Only fetch BPs and visits that happened on or before the selected calendar month
-- We use year and month comparisons to avoid timezone errors
LEFT OUTER JOIN reporting_patient_blood_pressures bps
    ON p.id = bps.patient_id AND cal.month = bps.month AND cal.year = bps.year
LEFT OUTER JOIN reporting_patient_visits visits
    ON p.id = visits.patient_id AND cal.month = visits.month AND cal.year = visits.year
LEFT OUTER JOIN medical_histories mh
    ON p.id = mh.patient_id
    AND mh.deleted_at IS NULL
INNER JOIN reporting_facilities registration_facility
    ON registration_facility.facility_id = p.registration_facility_id
INNER JOIN reporting_facilities assigned_facility
    ON assigned_facility.facility_id = p.assigned_facility_id
WHERE p.deleted_at IS NULL
ORDER BY
    p.id,
    cal.month_date ASC
