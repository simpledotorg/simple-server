WITH follow_up_blood_pressures AS (
    SELECT DISTINCT ON (day_of_year, facility_id, patient_id)
        p.id AS patient_id,
        p.gender::gender_enum as patient_gender,
        bp.id as visit_id,
        'BloodPressure' AS visit_type,
        bp.facility_id,
        bp.user_id,
        bp.recorded_at AS visited_at,
        cast(EXTRACT(DOY FROM bp.recorded_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
    FROM patients p
    INNER JOIN blood_pressures bp
        ON p.id = bp.patient_id
        AND date_trunc('day', bp.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
           > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
    WHERE p.deleted_at IS NULL
      AND bp.recorded_at > current_timestamp - interval '30 day'
),
     follow_up_blood_sugars AS (
         SELECT DISTINCT ON (day_of_year, facility_id, patient_id)
             p.id AS patient_id,
             p.gender::gender_enum as patient_gender,
             bs.id as visit_id,
             'BloodSugar' AS visit_type,
             bs.facility_id,
             bs.user_id,
             bs.recorded_at AS visited_at,
             cast(EXTRACT(DOY FROM bs.recorded_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year

         FROM patients p
         INNER JOIN blood_sugars bs
             ON p.id = bs.patient_id
             AND date_trunc('day', bs.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
                > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
         WHERE p.deleted_at IS NULL
           AND bs.recorded_at > current_timestamp - interval '30 day'
     ),
     follow_up_prescription_drugs AS (
         SELECT DISTINCT ON (day_of_year, facility_id, patient_id)
             p.id AS patient_id,
             p.gender::gender_enum as patient_gender,
             pd.id as visit_id,
             'PrescriptionDrug' AS visit_type,
             pd.facility_id,
             pd.user_id,
             pd.device_created_at AS visited_at,
             cast(EXTRACT(DOY FROM pd.device_created_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
         FROM patients p
         INNER JOIN prescription_drugs pd
             ON p.id = pd.patient_id
             AND date_trunc('day', pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
                > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
         WHERE p.deleted_at IS NULL
           AND pd.device_created_at > current_timestamp - interval '30 day'
     ),
     follow_up_appointments AS (
         SELECT DISTINCT ON (day_of_year, facility_id, patient_id)
             p.id AS patient_id,
             p.gender::gender_enum as patient_gender,
             app.id as visit_id,
             'Appointment' AS visit_type,
             app.creation_facility_id AS facility_id,
             app.user_id,
             app.device_created_at as visited_at,
             cast(EXTRACT(DOY FROM app.device_created_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
         FROM patients p
         INNER JOIN appointments app
             ON p.id = app.patient_id
             AND date_trunc('day', app.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
                > date_trunc('day', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
         WHERE p.deleted_at IS NULL
           AND app.device_created_at > current_timestamp - interval '30 day'
     ),
     registered_patients AS (
         SELECT DISTINCT ON (day_of_year, facility_id, patient_id)
             p.id AS patient_id,
             p.gender::gender_enum as patient_gender,
             p.id as visit_id,
             'Registration' as visit_type,
             p.assigned_facility_id as facility_id,
             p.registration_user_id as user_id,
             p.recorded_at as visited_at,
             cast(EXTRACT(DOY FROM p.recorded_at AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer) AS day_of_year
         FROM patients p
         WHERE p.deleted_at IS NULL
           AND p.recorded_at > current_timestamp - interval '30 day'
     ),
     all_follow_ups AS (
         SELECT *
         FROM
             follow_up_blood_pressures
         UNION (select * FROM follow_up_blood_sugars)
         UNION (select * FROM follow_up_prescription_drugs)
         UNION (select * FROM follow_up_appointments)
     ),
     all_follow_ups_with_medical_histories AS (
         SELECT DISTINCT ON (all_follow_ups.day_of_year, all_follow_ups.facility_id, all_follow_ups.patient_id)
             all_follow_ups.patient_id,
             all_follow_ups.patient_gender,
             all_follow_ups.facility_id,
             mh.diabetes,
             mh.hypertension,
             all_follow_ups.user_id,
             all_follow_ups.visit_id,
             all_follow_ups.visit_type,
             all_follow_ups.visited_at,
             all_follow_ups.day_of_year
         FROM all_follow_ups
         INNER JOIN medical_histories mh ON all_follow_ups.patient_id = mh.patient_id
     ),

     registered_patients_with_medical_histories AS (
         SELECT DISTINCT ON (registered_patients.day_of_year, registered_patients.facility_id, registered_patients.patient_id)
             registered_patients.patient_id,
             registered_patients.patient_gender,
             registered_patients.facility_id,
             mh.diabetes,
             mh.hypertension,
             registered_patients.user_id,
             registered_patients.visit_id,
             registered_patients.visit_type,
             registered_patients.visited_at,
             registered_patients.day_of_year
         FROM registered_patients
         INNER JOIN medical_histories mh ON registered_patients.patient_id = mh.patient_id
     ),

     daily_registered_patients AS (
         SELECT DISTINCT ON (facility_id, visit_date)
             facility_id,
             date(visited_at) as visit_date,
             day_of_year,

             count(*) FILTER (WHERE hypertension = 'yes' or diabetes = 'yes') AS daily_registrations_htn_or_dm,

             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_registrations_htn_and_dm,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_registrations_htn_and_dm_female,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_registrations_htn_and_dm_male,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_registrations_htn_and_dm_transgender,

             count(*) FILTER (WHERE hypertension = 'yes')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_registrations_htn_only,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'female')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_registrations_htn_only_female,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'male')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_registrations_htn_only_male,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'transgender')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_registrations_htn_only_transgender,

             count(*) FILTER (WHERE diabetes = 'yes')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_registrations_dm_only,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'female')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_registrations_dm_only_female,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'male')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_registrations_dm_only_male,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'transgender')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_registrations_dm_only_transgender
         FROM registered_patients_with_medical_histories
         GROUP BY facility_id, date(visited_at), day_of_year
     ),

     daily_follow_ups AS (
         SELECT DISTINCT ON (facility_id, visit_date)
             facility_id,
             date(visited_at) as visit_date,
             day_of_year,

             count(*) FILTER (WHERE hypertension = 'yes' or diabetes = 'yes') AS daily_follow_ups_htn_or_dm,

             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_follow_ups_htn_and_dm,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_follow_ups_htn_and_dm_female,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_follow_ups_htn_and_dm_male,
             count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_follow_ups_htn_and_dm_transgender,

             count(*) FILTER (WHERE hypertension = 'yes')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_follow_ups_htn_only,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'female')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_follow_ups_htn_only_female,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'male')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_follow_ups_htn_only_male,
             count(*) FILTER (WHERE hypertension = 'yes' and patient_gender = 'transgender')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_follow_ups_htn_only_transgender,

             count(*) FILTER (WHERE diabetes = 'yes')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes') AS daily_follow_ups_dm_only,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'female')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'female') AS daily_follow_ups_dm_only_female,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'male')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'male') AS daily_follow_ups_dm_only_male,
             count(*) FILTER (WHERE diabetes = 'yes' and patient_gender = 'transgender')
                 - count(*) FILTER (WHERE hypertension = 'yes' and diabetes = 'yes' and patient_gender = 'transgender') AS daily_follow_ups_dm_only_transgender
         FROM all_follow_ups_with_medical_histories
         GROUP BY facility_id, date(visited_at), day_of_year
     ),

     last_30_days AS (
         SELECT generate_series(current_timestamp - interval '30 day', current_timestamp, interval  '1 day'):: date as date
     )

SELECT
    rf.facility_region_slug,
    rf.facility_id,
    rf.facility_region_id,
    rf.block_region_id,
    rf.district_region_id,
    rf.state_region_id,
    last_30_days.date AS visit_date,
    cast(EXTRACT(DOY FROM last_30_days.date AT TIME ZONE 'UTC' at time zone (SELECT current_setting('TIMEZONE'))) as integer)
                      AS day_of_year,
    coalesce(daily_registered_patients.daily_registrations_htn_or_dm,0) AS daily_registrations_htn_or_dm,
    coalesce(daily_registered_patients.daily_registrations_htn_only,0) AS daily_registrations_htn_only,
    coalesce(daily_registered_patients.daily_registrations_htn_only_male,0) AS daily_registrations_htn_only_male,
    coalesce(daily_registered_patients.daily_registrations_htn_only_female,0) AS daily_registrations_htn_only_female,
    coalesce(daily_registered_patients.daily_registrations_htn_only_transgender,0) AS daily_registrations_htn_only_transgender,
    coalesce(daily_registered_patients.daily_registrations_dm_only,0) AS daily_registrations_dm_only,
    coalesce(daily_registered_patients.daily_registrations_dm_only_male,0) AS daily_registrations_dm_only_male,
    coalesce(daily_registered_patients.daily_registrations_dm_only_female,0) AS daily_registrations_dm_only_female,
    coalesce(daily_registered_patients.daily_registrations_dm_only_transgender,0) AS daily_registrations_dm_only_transgender,
    coalesce(daily_registered_patients.daily_registrations_htn_and_dm,0) AS daily_registrations_htn_and_dm,
    coalesce(daily_registered_patients.daily_registrations_htn_and_dm_male,0) AS daily_registrations_htn_and_dm_male,
    coalesce(daily_registered_patients.daily_registrations_htn_and_dm_female,0) AS daily_registrations_htn_and_dm_female,
    coalesce(daily_registered_patients.daily_registrations_htn_and_dm_transgender,0) AS daily_registrations_htn_and_dm_transgender,
    coalesce(daily_follow_ups.daily_follow_ups_htn_or_dm,0) AS daily_follow_ups_htn_or_dm,
    coalesce(daily_follow_ups.daily_follow_ups_htn_only,0) AS daily_follow_ups_htn_only,
    coalesce(daily_follow_ups.daily_follow_ups_htn_only_female,0) AS daily_follow_ups_htn_only_female,
    coalesce(daily_follow_ups.daily_follow_ups_htn_only_male,0) AS daily_follow_ups_htn_only_male,
    coalesce(daily_follow_ups.daily_follow_ups_htn_only_transgender,0) AS daily_follow_ups_htn_only_transgender,
    coalesce(daily_follow_ups.daily_follow_ups_dm_only,0) AS daily_follow_ups_dm_only,
    coalesce(daily_follow_ups.daily_follow_ups_dm_only_female,0) AS daily_follow_ups_dm_only_female,
    coalesce(daily_follow_ups.daily_follow_ups_dm_only_male,0) AS daily_follow_ups_dm_only_male,
    coalesce(daily_follow_ups.daily_follow_ups_dm_only_transgender,0) AS daily_follow_ups_dm_only_transgender,
    coalesce(daily_follow_ups.daily_follow_ups_htn_and_dm,0) AS daily_follow_ups_htn_and_dm,
    coalesce(daily_follow_ups.daily_follow_ups_htn_and_dm_male,0) AS daily_follow_ups_htn_and_dm_male,
    coalesce(daily_follow_ups.daily_follow_ups_htn_and_dm_female,0) AS daily_follow_ups_htn_and_dm_female,
    coalesce(daily_follow_ups.daily_follow_ups_htn_and_dm_transgender,0) AS daily_follow_ups_htn_and_dm_transgender

FROM reporting_facilities rf
INNER JOIN last_30_days
-- ensure a row for every facility and day combination
    ON TRUE
LEFT OUTER JOIN daily_registered_patients
    ON daily_registered_patients.visit_date = last_30_days.date
    AND daily_registered_patients.facility_id = rf.facility_id
LEFT OUTER JOIN daily_follow_ups
    ON daily_follow_ups.visit_date = last_30_days.date
    AND daily_follow_ups.facility_id = rf.facility_id
ORDER BY visit_date DESC
