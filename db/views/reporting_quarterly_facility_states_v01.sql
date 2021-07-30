WITH
    quarterly_cohort_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, quarter_string,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_quarter = 'visited_no_bp') AS visited_no_bp,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_quarter = 'controlled') AS controlled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_quarter = 'uncontrolled') AS uncontrolled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_quarter = 'missed_visit') AS missed_visit,
               COUNT(distinct(patient_id)) AS patients

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND (month::integer % 3 = 0 OR month_string = to_char(now(), 'YYYY-MM'))
          AND quarters_since_registration = 1
        GROUP BY 1, 2
    )

SELECT
cal.*,
rf.*,

quarterly_cohort_outcomes.controlled AS quarterly_cohort_controlled,
quarterly_cohort_outcomes.uncontrolled AS quarterly_cohort_uncontrolled,
quarterly_cohort_outcomes.missed_visit AS quarterly_cohort_missed_visit,
quarterly_cohort_outcomes.visited_no_bp AS quarterly_cohort_visited_no_bp,
quarterly_cohort_outcomes.patients quarterly_cohort_patients

-- ensure a row for every facility and quarter combination
FROM reporting_facilities rf
INNER JOIN reporting_months cal
-- only pick end of quarters, and current quarter in progress
    ON (month::integer % 3 = 0 OR month_string = to_char(now(), 'YYYY-MM'))
LEFT OUTER JOIN quarterly_cohort_outcomes
    ON quarterly_cohort_outcomes.quarter_string = cal.quarter_string
    AND quarterly_cohort_outcomes.region_id = rf.facility_region_id
