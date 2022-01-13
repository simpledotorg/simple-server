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
  )
SELECT registered_patients.*
FROM registered_patients
ORDER BY month_date desc