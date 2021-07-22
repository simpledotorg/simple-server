WITH
    registered_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_registrations
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    assigned_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS dead,
               COUNT(*) AS cumulative_assigned_patients
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    treatment_outcomes_in_last_3_months AS (
        SELECT assigned_facility_region_id AS region_id, month_date,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'controlled' AND htn_care_state = 'under_care') AS controlled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'controlled' AND htn_care_state = 'lost_to_follow_up') AS controlled_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'uncontrolled' AND htn_care_state = 'under_care') AS uncontrolled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'uncontrolled' AND htn_care_state = 'lost_to_follow_up') AS uncontrolled_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'missed_visit' AND htn_care_state = 'under_care') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'missed_visit' AND htn_care_state = 'lost_to_follow_up') AS missed_visit_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'visited_no_bp' AND htn_care_state = 'under_care') AS visited_no_bp_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'visited_no_bp' AND htn_care_state = 'lost_to_follow_up') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up
         FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    )

SELECT
cal.*,
rf.*,

rp.cumulative_registrations,
rp.monthly_registrations,
ap.under_care,
ap.lost_to_follow_up,
ap.dead,
ap.cumulative_assigned_patients,

tout.controlled_under_care,
tout.controlled_lost_to_follow_up,
tout.uncontrolled_under_care,
tout.uncontrolled_lost_to_follow_up,
tout.missed_visit_under_care,
tout.missed_visit_lost_to_follow_up,
tout.visited_no_bp_under_care,
tout.visited_no_bp_lost_to_follow_up,
tout.patients_under_care,
tout.patients_lost_to_follow_up

-- ensure a row for every facility and month combination
FROM reporting_facilities rf
INNER JOIN reporting_months cal
    ON true
LEFT OUTER JOIN registered_patients rp
    ON rp.month_date = cal.month_date
    AND rp.region_id = rf.facility_region_id
LEFT OUTER JOIN assigned_patients ap
    ON ap.month_date = cal.month_date
    AND ap.region_id = rf.facility_region_id
LEFT OUTER JOIN treatment_outcomes_in_last_3_months tout
    ON tout.month_date = cal.month_date
    AND tout.region_id = rf.facility_region_id