WITH monthly_registration_patient_states AS
(SELECT
  registration_facility_id AS facility_id,
  month_date,
  gender,
  hypertension,
  diabetes
FROM reporting_patient_states
WHERE months_since_registration = 0
),
 registered_patients AS
     (SELECT
          facility_id,
          month_date,

          count(*) AS monthly_registrations_all,
          count(*) FILTER (WHERE hypertension = 'yes') AS monthly_registrations_htn_all,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'female') AS monthly_registrations_htn_female,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'male') AS monthly_registrations_htn_male,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'transgender') AS monthly_registrations_htn_transgender,
          count(*) FILTER (WHERE diabetes = 'yes') AS monthly_registrations_dm_all,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'female') AS monthly_registrations_dm_female,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'male') AS monthly_registrations_dm_male,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'transgender') AS monthly_registrations_dm_transgender,

          count(*) FILTER (WHERE hypertension = 'yes' or diabetes = 'yes') AS monthly_registrations_htn_or_dm,
          count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_registrations_htn_and_dm,
          count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'female') AS monthly_registrations_htn_and_dm_female,
          count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'male') AS monthly_registrations_htn_and_dm_male,
          count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'transgender') AS monthly_registrations_htn_and_dm_transgender,

          count(*) FILTER (WHERE hypertension = 'yes')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_registrations_htn_only,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'female')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'female') AS monthly_registrations_htn_only_female,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'male')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'male') AS monthly_registrations_htn_only_male,
          count(*) FILTER (WHERE hypertension = 'yes' and gender = 'transgender')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'transgender')AS monthly_registrations_htn_only_transgender,

          count(*) FILTER (WHERE diabetes = 'yes')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_registrations_dm_only,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'female')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'female') AS monthly_registrations_dm_only_female,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'male')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'male') AS monthly_registrations_dm_only_male,
          count(*) FILTER (WHERE diabetes = 'yes' and gender = 'transgender')
              - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and gender = 'transgender')AS monthly_registrations_dm_only_transgender
      FROM monthly_registration_patient_states
      GROUP BY facility_id, month_date
 ),
 follow_ups AS
     (SELECT
          facility_id,
          month_date,

          count(distinct(patient_id)) AS monthly_follow_ups_all,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes') AS monthly_follow_ups_htn_all,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'female') AS monthly_follow_ups_htn_female,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'male') AS monthly_follow_ups_htn_male,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'transgender') AS monthly_follow_ups_htn_transgender,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes') AS monthly_follow_ups_dm_all,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'female') AS monthly_follow_ups_dm_female,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'male') AS monthly_follow_ups_dm_male,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'transgender') AS monthly_follow_ups_dm_transgender,

          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' or diabetes = 'yes') AS monthly_follow_ups_htn_or_dm,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_follow_ups_htn_and_dm,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS monthly_follow_ups_htn_and_dm_female,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS monthly_follow_ups_htn_and_dm_male,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS monthly_follow_ups_htn_and_dm_transgender,

          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_follow_ups_htn_only,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'female')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS monthly_follow_ups_htn_only_female,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'male')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS monthly_follow_ups_htn_only_male,
          count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and patient_gender = 'transgender')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender')AS monthly_follow_ups_htn_only_transgender,

          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS monthly_follow_ups_dm_only,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'female')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS monthly_follow_ups_dm_only_female,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'male')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS monthly_follow_ups_dm_only_male,
          count(distinct(patient_id)) FILTER (WHERE diabetes = 'yes' and patient_gender = 'transgender')
              - count(distinct(patient_id)) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender')AS monthly_follow_ups_dm_only_transgender
      FROM reporting_patient_follow_ups
      GROUP BY facility_id, month_date
 )
SELECT
    rf.facility_region_slug,
    rf.facility_id,
    rf.facility_region_id,
    rf.block_region_id,
    rf.district_region_id,
    rf.state_region_id,

    cal.month_date,

    coalesce(registered_patients.monthly_registrations_all,0) AS monthly_registrations_all,
    coalesce(registered_patients.monthly_registrations_htn_all,0) AS monthly_registrations_htn_all,
    coalesce(registered_patients.monthly_registrations_htn_male,0) AS monthly_registrations_htn_male,
    coalesce(registered_patients.monthly_registrations_htn_female,0) AS monthly_registrations_htn_female,
    coalesce(registered_patients.monthly_registrations_htn_transgender,0) AS monthly_registrations_htn_transgender,
    coalesce(registered_patients.monthly_registrations_dm_all,0) AS monthly_registrations_dm_all,
    coalesce(registered_patients.monthly_registrations_dm_male,0) AS monthly_registrations_dm_male,
    coalesce(registered_patients.monthly_registrations_dm_female,0) AS monthly_registrations_dm_female,
    coalesce(registered_patients.monthly_registrations_dm_transgender,0) AS monthly_registrations_dm_transgender,

    coalesce(follow_ups.monthly_follow_ups_all,0) AS monthly_follow_ups_all,
    coalesce(follow_ups.monthly_follow_ups_htn_all,0) AS monthly_follow_ups_htn_all,
    coalesce(follow_ups.monthly_follow_ups_htn_female,0) AS monthly_follow_ups_htn_female,
    coalesce(follow_ups.monthly_follow_ups_htn_male,0) AS monthly_follow_ups_htn_male,
    coalesce(follow_ups.monthly_follow_ups_htn_transgender,0) AS monthly_follow_ups_htn_transgender,
    coalesce(follow_ups.monthly_follow_ups_dm_all,0) AS monthly_follow_ups_dm_all,
    coalesce(follow_ups.monthly_follow_ups_dm_female,0) AS monthly_follow_ups_dm_female,
    coalesce(follow_ups.monthly_follow_ups_dm_male,0) AS monthly_follow_ups_dm_male,
    coalesce(follow_ups.monthly_follow_ups_dm_transgender,0) AS monthly_follow_ups_dm_transgender,

    coalesce(registered_patients.monthly_registrations_htn_or_dm, 0) AS monthly_registrations_htn_or_dm,
    coalesce(registered_patients.monthly_registrations_htn_only, 0) AS monthly_registrations_htn_only,
    coalesce(registered_patients.monthly_registrations_htn_only_male, 0) AS monthly_registrations_htn_only_male,
    coalesce(registered_patients.monthly_registrations_htn_only_female, 0) AS monthly_registrations_htn_only_female,
    coalesce(registered_patients.monthly_registrations_htn_only_transgender, 0) AS monthly_registrations_htn_only_transgender,
    coalesce(registered_patients.monthly_registrations_dm_only, 0) AS monthly_registrations_dm_only,
    coalesce(registered_patients.monthly_registrations_dm_only_male, 0) AS monthly_registrations_dm_only_male,
    coalesce(registered_patients.monthly_registrations_dm_only_female, 0) AS monthly_registrations_dm_only_female,
    coalesce(registered_patients.monthly_registrations_dm_only_transgender, 0) AS monthly_registrations_dm_only_transgender,
    coalesce(registered_patients.monthly_registrations_htn_and_dm, 0) AS monthly_registrations_htn_and_dm,
    coalesce(registered_patients.monthly_registrations_htn_and_dm_male, 0) AS monthly_registrations_htn_and_dm_male,
    coalesce(registered_patients.monthly_registrations_htn_and_dm_female, 0) AS monthly_registrations_htn_and_dm_female,
    coalesce(registered_patients.monthly_registrations_htn_and_dm_transgender, 0) AS monthly_registrations_htn_and_dm_transgender,

    coalesce(follow_ups.monthly_follow_ups_htn_or_dm, 0) AS monthly_follow_ups_htn_or_dm,
    coalesce(follow_ups.monthly_follow_ups_htn_only, 0) AS monthly_follow_ups_htn_only,
    coalesce(follow_ups.monthly_follow_ups_htn_only_female, 0) AS monthly_follow_ups_htn_only_female,
    coalesce(follow_ups.monthly_follow_ups_htn_only_male, 0) AS monthly_follow_ups_htn_only_male,
    coalesce(follow_ups.monthly_follow_ups_htn_only_transgender, 0) AS monthly_follow_ups_htn_only_transgender,
    coalesce(follow_ups.monthly_follow_ups_dm_only, 0) AS monthly_follow_ups_dm_only,
    coalesce(follow_ups.monthly_follow_ups_dm_only_female, 0) AS monthly_follow_ups_dm_only_female,
    coalesce(follow_ups.monthly_follow_ups_dm_only_male, 0) AS monthly_follow_ups_dm_only_male,
    coalesce(follow_ups.monthly_follow_ups_dm_only_transgender, 0) AS monthly_follow_ups_dm_only_transgender,
    coalesce(follow_ups.monthly_follow_ups_htn_and_dm, 0) AS monthly_follow_ups_htn_and_dm,
    coalesce(follow_ups.monthly_follow_ups_htn_and_dm_male, 0) AS monthly_follow_ups_htn_and_dm_male,
    coalesce(follow_ups.monthly_follow_ups_htn_and_dm_female, 0) AS monthly_follow_ups_htn_and_dm_female,
    coalesce(follow_ups.monthly_follow_ups_htn_and_dm_transgender, 0) AS monthly_follow_ups_htn_and_dm_transgender
FROM reporting_facilities rf
INNER JOIN reporting_months cal
-- ensure a row for every facility and month combination
    ON TRUE
LEFT OUTER JOIN registered_patients
    ON registered_patients.month_date = cal.month_date
    AND registered_patients.facility_id = rf.facility_id
LEFT OUTER JOIN follow_ups
    ON follow_ups.month_date = cal.month_date
    AND follow_ups.facility_id = rf.facility_id
ORDER BY cal.month_date desc
