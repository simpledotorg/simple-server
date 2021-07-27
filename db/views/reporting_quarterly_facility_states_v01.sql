WITH
    quarterly_cohort_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, quarter_string,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_quarter = 'controlled') AS controlled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_quarter = 'uncontrolled') AS uncontrolled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_quarter = 'missed_visit') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_quarter = 'visited_no_bp') AS visited_no_bp_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_quarter = 'missed_visit') AS missed_visit_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_quarter = 'visited_no_bp') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up

         FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND quarters_since_registration = 1
        GROUP BY 1, 2
    )

SELECT
cal.*,
rf.*,

quarterly_outcomes.controlled_under_care,
quarterly_outcomes.uncontrolled_under_care,
quarterly_outcomes.missed_visit_under_care,
quarterly_outcomes.visited_no_bp_under_care,

quarterly_outcomes.missed_visit_lost_to_follow_up,
quarterly_outcomes.visited_no_bp_lost_to_follow_up,

quarterly_outcomes.patients_under_care,
quarterly_outcomes.patients_lost_to_follow_up

-- ensure a row for every facility and quarter combination
FROM reporting_facilities rf
INNER JOIN reporting_months cal
-- only pick end of quarters, and current quarter in progress
    ON month::integer % 3 = 0 OR month_string = to_char(now(), 'YYYY-MM')
LEFT OUTER JOIN quarterly_cohort_outcomes quarterly_outcomes
    ON quarterly_outcomes.quarter_string = cal.quarter_string
    AND quarterly_outcomes.region_id = rf.facility_region_id