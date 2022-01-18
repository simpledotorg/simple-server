WITH registered_patients AS
  (SELECT
    registration_facility_region_id AS facility_region_id, month_date,
    count(*) AS monthly_registrations_all,
  
    count(*) FILTER (WHERE hypertension = 'yes') AS monthly_registrations_htn_all,
    count(*) FILTER (WHERE hypertension = 'yes' and gender = 'female') AS monthly_registrations_htn_female,
    count(*) FILTER (WHERE hypertension = 'yes' and gender = 'male') AS monthly_registrations_htn_male,
    count(*) FILTER (WHERE hypertension = 'yes' and gender = 'transgender') AS monthly_registrations_htn_transgender,
  
    count(*) FILTER (WHERE diabetes = 'yes') AS monthly_registrations_dm_all,
    count(*) FILTER (WHERE diabetes = 'yes' and gender = 'female') AS monthly_registrations_dm_female,
    count(*) FILTER (WHERE diabetes = 'yes' and gender = 'male') AS monthly_registrations_dm_male,
    count(*) FILTER (WHERE diabetes = 'yes' and gender = 'transgender') AS monthly_registrations_dm_transgender
  FROM reporting_patient_states 
  WHERE months_since_registration = 0
  GROUP BY
    facility_region_id, month_date
  ),
follow_ups AS
  (SELECT
    facility_id, month_date,
    count(*) AS monthly_follow_ups_all,

    count(*) FILTER (WHERE hypertension = 'yes') AS monthly_follow_ups_htn_all,
    count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'female') AS monthly_follow_ups_htn_female,
    count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'male') AS monthly_follow_ups_htn_male,
    count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'transgender') AS monthly_follow_ups_htn_transgender,

    count(*) FILTER (WHERE diabetes = 'yes') AS monthly_follow_ups_dm_all,
    count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'female') AS monthly_follow_ups_dm_female,
    count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'male') AS monthly_follow_ups_dm_male,
    count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'transgender') AS monthly_follow_ups_dm_transgender
  FROM reporting_patient_follow_ups
  GROUP BY facility_id, month_date
)
SELECT 
  rf.facility_region_slug,
  rf.block_region_id,
  rf.district_region_id,
  rf.state_region_id,
  cal.month_string,
  registered_patients.*,
  follow_ups.monthly_follow_ups_all,
  follow_ups.monthly_follow_ups_htn_female,
  follow_ups.monthly_follow_ups_htn_male,
  follow_ups.monthly_follow_ups_htn_transgender,
  follow_ups.monthly_follow_ups_dm_all,
  follow_ups.monthly_follow_ups_dm_female,
  follow_ups.monthly_follow_ups_dm_male,
  follow_ups.monthly_follow_ups_dm_transgender
FROM reporting_facilities rf
INNER JOIN reporting_months cal
    ON TRUE
LEFT OUTER JOIN registered_patients
  ON registered_patients.month_date = cal.month_date
  AND registered_patients.facility_region_id = rf.facility_region_id
LEFT OUTER JOIN follow_ups
  ON follow_ups.month_date = cal.month_date
  AND follow_ups.facility_id = rf.facility_id
ORDER BY cal.month_date desc