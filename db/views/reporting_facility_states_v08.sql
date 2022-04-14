WITH
    registered_htn_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_registrations

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    registered_diabetes_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_registrations

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
        GROUP BY 1, 2
    ),

    assigned_htn_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS dead,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state != 'dead') AS cumulative_assigned_htn_patients

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    assigned_diabetes_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS dead,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state != 'dead') AS cumulative_assigned_diabetes_patients

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
        GROUP BY 1, 2
    ),

    adjusted_htn_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'controlled') AS controlled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'uncontrolled') AS uncontrolled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    ),

    adjusted_diabetes_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200') AS bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300') AS bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300') AS bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND diabetes_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND diabetes_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    ),

    monthly_htn_cohort_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'controlled') AS controlled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'uncontrolled') AS uncontrolled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'missed_visit') AS missed_visit,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'visited_no_bp') AS visited_no_bp,
               COUNT(distinct(patient_id)) AS patients

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration = 2
        GROUP BY 1, 2
    ),

    monthly_overdue_calls AS (
        SELECT appointment_facility_region_id AS region_id, month_date,
               COUNT(distinct(appointment_id)) AS call_results
        FROM reporting_overdue_calls
        GROUP BY 1, 2
    ),

    monthly_htn_follow_ups AS (
        SELECT facility_id, month_date, COUNT(distinct(patient_id)) as follow_ups
        FROM reporting_patient_follow_ups
        WHERE hypertension = 'yes'
        GROUP BY facility_id, month_date
    ),

    monthly_diabetes_follow_ups AS (
    SELECT facility_id, month_date, COUNT(distinct(patient_id)) as follow_ups
    FROM reporting_patient_follow_ups
    WHERE diabetes = 'yes'
    GROUP BY facility_id, month_date
    )

SELECT
-- months and facilities
cal.*,
rf.*,

-- registration counts of hypertensive patients
registered_htn_patients.cumulative_registrations,
registered_htn_patients.monthly_registrations,

-- registration counts of diabetic patients
registered_diabetes_patients.cumulative_registrations,
registered_diabetes_patients.monthly_registrations,

-- assigned hypertensive patient counts by care state
assigned_htn_patients.under_care,
assigned_htn_patients.lost_to_follow_up,
assigned_htn_patients.dead,
assigned_htn_patients.cumulative_assigned_htn_patients,

-- assigned diabetic patient counts by care state
assigned_diabetes_patients.under_care,
assigned_diabetes_patients.lost_to_follow_up,
assigned_diabetes_patients.dead,
assigned_diabetes_patients.cumulative_assigned_diabetes_patients,

-- adjusted htn outcomes
adjusted_htn_outcomes.controlled_under_care AS adjusted_controlled_under_care,
adjusted_htn_outcomes.uncontrolled_under_care AS adjusted_uncontrolled_under_care,
adjusted_htn_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
adjusted_htn_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,

adjusted_htn_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
adjusted_htn_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,

adjusted_htn_outcomes.patients_under_care AS adjusted_patients_under_care,
adjusted_htn_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,

-- adjusted diabetes outcomes
adjusted_diabetes_outcomes.bs_below_200_under_care AS adjusted_bs_below_200_under_care,
adjusted_diabetes_outcomes.bs_200_to_300_under_care AS adjusted_bs_200_to_300_under_care,
adjusted_diabetes_outcomes.bs_over_300_under_care AS adjusted_bs_over_300_under_care,
adjusted_diabetes_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
adjusted_diabetes_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,

adjusted_diabetes_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
adjusted_diabetes_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,

adjusted_diabetes_outcomes.patients_under_care AS adjusted_patients_under_care,
adjusted_diabetes_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,

-- monthly cohort outcomes
monthly_htn_cohort_outcomes.controlled AS monthly_cohort_controlled,
monthly_htn_cohort_outcomes.uncontrolled AS monthly_cohort_uncontrolled,
monthly_htn_cohort_outcomes.missed_visit AS monthly_cohort_missed_visit,
monthly_htn_cohort_outcomes.visited_no_bp AS monthly_cohort_visited_no_bp,
monthly_htn_cohort_outcomes.patients AS monthly_cohort_patients,

-- monthly overdue calls
monthly_overdue_calls.call_results AS monthly_overdue_calls,

-- monthly htn follow ups
monthly_htn_follow_ups.follow_ups AS monthly_htn_follow_ups,

-- monthly diabetes follow ups
monthly_diabetes_follow_ups.follow_ups AS monthly_diabetes_follow_ups,

-- appointment scheduled days distribution
reporting_facility_appointment_scheduled_days.total_appts_scheduled AS total_appts_scheduled,
reporting_facility_appointment_scheduled_days.appts_scheduled_0_to_14_days AS appts_scheduled_0_to_14_days,
reporting_facility_appointment_scheduled_days.appts_scheduled_15_to_31_days AS appts_scheduled_15_to_31_days,
reporting_facility_appointment_scheduled_days.appts_scheduled_32_to_62_days AS appts_scheduled_32_to_62_days,
reporting_facility_appointment_scheduled_days.appts_scheduled_more_than_62_days AS appts_scheduled_more_than_62_days

FROM reporting_facilities rf
INNER JOIN reporting_months cal
-- ensure a row for every facility and month combination
    ON TRUE
LEFT OUTER JOIN registered_htn_patients
    ON registered_htn_patients.month_date = cal.month_date
    AND registered_htn_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN assigned_htn_patients
    ON assigned_htn_patients.month_date = cal.month_date
    AND assigned_htn_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN adjusted_htn_outcomes
    ON adjusted_htn_outcomes.month_date = cal.month_date
    AND adjusted_htn_outcomes.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_htn_cohort_outcomes
    ON monthly_htn_cohort_outcomes.month_date = cal.month_date
    AND monthly_htn_cohort_outcomes.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_overdue_calls
    ON monthly_overdue_calls.month_date = cal.month_date
    AND monthly_overdue_calls.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_htn_follow_ups
    ON monthly_htn_follow_ups.month_date = cal.month_date
    AND monthly_htn_follow_ups.facility_id = rf.facility_id
LEFT OUTER JOIN reporting_facility_appointment_scheduled_days
    ON reporting_facility_appointment_scheduled_days.month_date = cal.month_date
    AND reporting_facility_appointment_scheduled_days.facility_id = rf.facility_id
