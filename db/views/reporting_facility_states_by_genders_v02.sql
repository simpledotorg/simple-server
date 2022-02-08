WITH adjusted_outcomes AS (
  SELECT assigned_facility_region_id AS region_id, month_date,
    COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND gender = 'female' AND htn_treatment_outcome_in_last_3_months = 'controlled') AS monthly_controlled_htn_female,
    COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND gender = 'male' AND htn_treatment_outcome_in_last_3_months = 'controlled') AS monthly_controlled_htn_male,
    COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND gender = 'female' AND htn_treatment_outcome_in_last_3_months = 'uncontrolled') AS monthly_uncontrolled_htn_female,
    COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND gender = 'male' AND htn_treatment_outcome_in_last_3_months = 'uncontrolled') AS monthly_uncontrolled_htn_male
  FROM reporting_patient_states
    WHERE hypertension = 'yes'
      AND months_since_registration >= 3
    GROUP BY 1, 2
)
SELECT 
  cal.*,
  rf.*,
  adjusted_outcomes.monthly_controlled_htn_female,
  adjusted_outcomes.monthly_controlled_htn_male,
  adjusted_outcomes.monthly_uncontrolled_htn_female,
  adjusted_outcomes.monthly_uncontrolled_htn_male
FROM reporting_facilities rf
INNER JOIN reporting_months cal
  -- ensure a row for every facility and month combination
  ON TRUE
LEFT OUTER JOIN adjusted_outcomes
  ON adjusted_outcomes.month_date = cal.month_date
  AND adjusted_outcomes.region_id = rf.facility_region_id


