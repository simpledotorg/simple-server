class UpdateReportingFacilityDailyFollowUpsAndRegistrationsToVersion3 < ActiveRecord::Migration[6.1]
  def up
    drop_view :reporting_facility_daily_follow_ups_and_registrations, materialized: true
    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_daily_follow_ups_and_registrations AS
      WITH follow_up_blood_pressures AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), bp.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bp.id AS visit_id,
            'BloodPressure'::text AS visit_type,
            bp.facility_id,
            bp.user_id,
            bp.recorded_at AS visited_at,
            (EXTRACT(doy FROM ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('day'::text, ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL) AND (bp.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_blood_sugars AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), bs.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bs.id AS visit_id,
            'BloodSugar'::text AS visit_type,
            bs.facility_id,
            bs.user_id,
            bs.recorded_at AS visited_at,
            (EXTRACT(doy FROM ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.blood_sugars bs ON (((p.id = bs.patient_id) AND (date_trunc('day'::text, ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL) AND (bs.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_prescription_drugs AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), pd.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            pd.id AS visit_id,
            'PrescriptionDrug'::text AS visit_type,
            pd.facility_id,
            pd.user_id,
            pd.device_created_at AS visited_at,
            (EXTRACT(doy FROM ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.prescription_drugs pd ON (((p.id = pd.patient_id) AND (date_trunc('day'::text, ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL) AND (pd.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_appointments AS (
          SELECT DISTINCT ON (((EXTRACT(doy FROM ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), app.creation_facility_id, p.id) p.id AS patient_id,
              (p.gender)::public.gender_enum AS patient_gender,
              app.id AS visit_id,
              'Appointment'::text AS visit_type,
              app.creation_facility_id AS facility_id,
              app.user_id,
              app.device_created_at AS visited_at,
              (EXTRACT(doy FROM ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
            FROM (public.patients p
              JOIN public.appointments app ON (((p.id = app.patient_id) AND (date_trunc('day'::text, ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
            WHERE ((p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL) AND (app.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
          ), registered_patients AS (
          SELECT DISTINCT ON (((EXTRACT(doy FROM ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), p.registration_facility_id, p.id) p.id AS patient_id,
              (p.gender)::public.gender_enum AS patient_gender,
              p.id AS visit_id,
              'Registration'::text AS visit_type,
              p.registration_facility_id AS facility_id,
              p.registration_user_id AS user_id,
              p.diagnosed_confirmed_at AS visited_at,
              (EXTRACT(doy FROM ((p.diagnosed_confirmed_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
            FROM public.patients p
            WHERE ((p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL) AND (p.diagnosed_confirmed_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
          ), all_follow_ups AS (
          SELECT follow_up_blood_pressures.patient_id,
              follow_up_blood_pressures.patient_gender,
              follow_up_blood_pressures.visit_id,
              follow_up_blood_pressures.visit_type,
              follow_up_blood_pressures.facility_id,
              follow_up_blood_pressures.user_id,
              follow_up_blood_pressures.visited_at,
              follow_up_blood_pressures.day_of_year
            FROM follow_up_blood_pressures
          UNION
          SELECT follow_up_blood_sugars.patient_id,
              follow_up_blood_sugars.patient_gender,
              follow_up_blood_sugars.visit_id,
              follow_up_blood_sugars.visit_type,
              follow_up_blood_sugars.facility_id,
              follow_up_blood_sugars.user_id,
              follow_up_blood_sugars.visited_at,
              follow_up_blood_sugars.day_of_year
            FROM follow_up_blood_sugars
          UNION
          SELECT follow_up_prescription_drugs.patient_id,
              follow_up_prescription_drugs.patient_gender,
              follow_up_prescription_drugs.visit_id,
              follow_up_prescription_drugs.visit_type,
              follow_up_prescription_drugs.facility_id,
              follow_up_prescription_drugs.user_id,
              follow_up_prescription_drugs.visited_at,
              follow_up_prescription_drugs.day_of_year
            FROM follow_up_prescription_drugs
          UNION
          SELECT follow_up_appointments.patient_id,
              follow_up_appointments.patient_gender,
              follow_up_appointments.visit_id,
              follow_up_appointments.visit_type,
              follow_up_appointments.facility_id,
              follow_up_appointments.user_id,
              follow_up_appointments.visited_at,
              follow_up_appointments.day_of_year
            FROM follow_up_appointments
          ), all_follow_ups_with_medical_histories AS (
          SELECT DISTINCT ON (all_follow_ups.day_of_year, all_follow_ups.facility_id, all_follow_ups.patient_id) all_follow_ups.patient_id,
              all_follow_ups.patient_gender,
              all_follow_ups.facility_id,
              mh.diabetes,
              mh.hypertension,
              all_follow_ups.user_id,
              all_follow_ups.visit_id,
              all_follow_ups.visit_type,
              all_follow_ups.visited_at,
              all_follow_ups.day_of_year
            FROM (all_follow_ups
              JOIN public.medical_histories mh ON ((all_follow_ups.patient_id = mh.patient_id)))
          ), registered_patients_with_medical_histories AS (
          SELECT DISTINCT ON (registered_patients.day_of_year, registered_patients.facility_id, registered_patients.patient_id) registered_patients.patient_id,
              registered_patients.patient_gender,
              registered_patients.facility_id,
              mh.diabetes,
              mh.hypertension,
              registered_patients.user_id,
              registered_patients.visit_id,
              registered_patients.visit_type,
              registered_patients.visited_at,
              registered_patients.day_of_year
            FROM (registered_patients
              JOIN public.medical_histories mh ON ((registered_patients.patient_id = mh.patient_id)))
          ), daily_registered_patients AS (
          SELECT DISTINCT ON (registered_patients_with_medical_histories.facility_id, (date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))) registered_patients_with_medical_histories.facility_id,
              date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) AS visit_date,
              registered_patients_with_medical_histories.day_of_year,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) OR (registered_patients_with_medical_histories.diabetes = 'yes'::text))) AS daily_registrations_htn_or_dm,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text))) AS daily_registrations_htn_and_dm,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) AS daily_registrations_htn_and_dm_female,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) AS daily_registrations_htn_and_dm_male,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) AS daily_registrations_htn_and_dm_transgender,
              (count(*) FILTER (WHERE (registered_patients_with_medical_histories.hypertension = 'yes'::text)) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text)))) AS daily_registrations_htn_only,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_registrations_htn_only_female,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_registrations_htn_only_male,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_registrations_htn_only_transgender,
              (count(*) FILTER (WHERE (registered_patients_with_medical_histories.diabetes = 'yes'::text)) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text)))) AS daily_registrations_dm_only,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_registrations_dm_only_female,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_registrations_dm_only_male,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_registrations_dm_only_transgender
            FROM registered_patients_with_medical_histories
            GROUP BY registered_patients_with_medical_histories.facility_id, (date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))), registered_patients_with_medical_histories.day_of_year
          ), daily_follow_ups AS (
          SELECT DISTINCT ON (all_follow_ups_with_medical_histories.facility_id, (date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))) all_follow_ups_with_medical_histories.facility_id,
              date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) AS visit_date,
              all_follow_ups_with_medical_histories.day_of_year,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) OR (all_follow_ups_with_medical_histories.diabetes = 'yes'::text))) AS daily_follow_ups_htn_or_dm,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text))) AS daily_follow_ups_htn_and_dm,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_female,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_male,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_transgender,
              (count(*) FILTER (WHERE (all_follow_ups_with_medical_histories.hypertension = 'yes'::text)) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)))) AS daily_follow_ups_htn_only,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_follow_ups_htn_only_female,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_follow_ups_htn_only_male,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_follow_ups_htn_only_transgender,
              (count(*) FILTER (WHERE (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)))) AS daily_follow_ups_dm_only,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_follow_ups_dm_only_female,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_follow_ups_dm_only_male,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_follow_ups_dm_only_transgender
            FROM all_follow_ups_with_medical_histories
            GROUP BY all_follow_ups_with_medical_histories.facility_id, (date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))), all_follow_ups_with_medical_histories.day_of_year
          ), last_30_days AS (
          SELECT (generate_series((CURRENT_TIMESTAMP - '30 days'::interval), CURRENT_TIMESTAMP, '1 day'::interval))::date AS date
          )
        SELECT rf.facility_region_slug,
            rf.facility_id,
            rf.facility_region_id,
            rf.block_region_id,
            rf.district_region_id,
            rf.state_region_id,
            last_30_days.date AS visit_date,
            (EXTRACT(doy FROM ((last_30_days.date AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year,
            COALESCE(daily_registered_patients.daily_registrations_htn_or_dm, (0)::bigint) AS daily_registrations_htn_or_dm,
            COALESCE(daily_registered_patients.daily_registrations_htn_only, (0)::bigint) AS daily_registrations_htn_only,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_male, (0)::bigint) AS daily_registrations_htn_only_male,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_female, (0)::bigint) AS daily_registrations_htn_only_female,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_transgender, (0)::bigint) AS daily_registrations_htn_only_transgender,
            COALESCE(daily_registered_patients.daily_registrations_dm_only, (0)::bigint) AS daily_registrations_dm_only,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_male, (0)::bigint) AS daily_registrations_dm_only_male,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_female, (0)::bigint) AS daily_registrations_dm_only_female,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_transgender, (0)::bigint) AS daily_registrations_dm_only_transgender,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm, (0)::bigint) AS daily_registrations_htn_and_dm,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_male, (0)::bigint) AS daily_registrations_htn_and_dm_male,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_female, (0)::bigint) AS daily_registrations_htn_and_dm_female,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_transgender, (0)::bigint) AS daily_registrations_htn_and_dm_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_or_dm, (0)::bigint) AS daily_follow_ups_htn_or_dm,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only, (0)::bigint) AS daily_follow_ups_htn_only,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_female, (0)::bigint) AS daily_follow_ups_htn_only_female,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_male, (0)::bigint) AS daily_follow_ups_htn_only_male,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_transgender, (0)::bigint) AS daily_follow_ups_htn_only_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only, (0)::bigint) AS daily_follow_ups_dm_only,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_female, (0)::bigint) AS daily_follow_ups_dm_only_female,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_male, (0)::bigint) AS daily_follow_ups_dm_only_male,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_transgender, (0)::bigint) AS daily_follow_ups_dm_only_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm, (0)::bigint) AS daily_follow_ups_htn_and_dm,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_male, (0)::bigint) AS daily_follow_ups_htn_and_dm_male,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_female, (0)::bigint) AS daily_follow_ups_htn_and_dm_female,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_transgender, (0)::bigint) AS daily_follow_ups_htn_and_dm_transgender
          FROM (((public.reporting_facilities rf
            JOIN last_30_days ON (true))
            LEFT JOIN daily_registered_patients ON (((daily_registered_patients.visit_date = last_30_days.date) AND (daily_registered_patients.facility_id = rf.facility_id))))
            LEFT JOIN daily_follow_ups ON (((daily_follow_ups.visit_date = last_30_days.date) AND (daily_follow_ups.facility_id = rf.facility_id))))
          ORDER BY last_30_days.date DESC
          WITH NO DATA;
    SQL

    add_index :reporting_facility_daily_follow_ups_and_registrations, [:facility_id, :visit_date], name: "fd_far_facility_id_visit_date", unique: true
    add_index :reporting_facility_daily_follow_ups_and_registrations, [:facility_region_id, :visit_date], name: "index_df_facility_region_id_visit_date", unique: true
  end

  def down
    drop_view :reporting_facility_daily_follow_ups_and_registrations, materialized: true
    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_daily_follow_ups_and_registrations AS
      WITH follow_up_blood_pressures AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), bp.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bp.id AS visit_id,
            'BloodPressure'::text AS visit_type,
            bp.facility_id,
            bp.user_id,
            bp.recorded_at AS visited_at,
            (EXTRACT(doy FROM ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('day'::text, ((bp.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL) AND (bp.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_blood_sugars AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), bs.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            bs.id AS visit_id,
            'BloodSugar'::text AS visit_type,
            bs.facility_id,
            bs.user_id,
            bs.recorded_at AS visited_at,
            (EXTRACT(doy FROM ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.blood_sugars bs ON (((p.id = bs.patient_id) AND (date_trunc('day'::text, ((bs.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL) AND (bs.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_prescription_drugs AS (
        SELECT DISTINCT ON (((EXTRACT(doy FROM ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), pd.facility_id, p.id) p.id AS patient_id,
            (p.gender)::public.gender_enum AS patient_gender,
            pd.id AS visit_id,
            'PrescriptionDrug'::text AS visit_type,
            pd.facility_id,
            pd.user_id,
            pd.device_created_at AS visited_at,
            (EXTRACT(doy FROM ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
          FROM (public.patients p
            JOIN public.prescription_drugs pd ON (((p.id = pd.patient_id) AND (date_trunc('day'::text, ((pd.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
          WHERE ((p.deleted_at IS NULL) AND (pd.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
        ), follow_up_appointments AS (
          SELECT DISTINCT ON (((EXTRACT(doy FROM ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), app.creation_facility_id, p.id) p.id AS patient_id,
              (p.gender)::public.gender_enum AS patient_gender,
              app.id AS visit_id,
              'Appointment'::text AS visit_type,
              app.creation_facility_id AS facility_id,
              app.user_id,
              app.device_created_at AS visited_at,
              (EXTRACT(doy FROM ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
            FROM (public.patients p
              JOIN public.appointments app ON (((p.id = app.patient_id) AND (date_trunc('day'::text, ((app.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) > date_trunc('day'::text, ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))))))
            WHERE ((p.deleted_at IS NULL) AND (app.device_created_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
          ), registered_patients AS (
          SELECT DISTINCT ON (((EXTRACT(doy FROM ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer), p.registration_facility_id, p.id) p.id AS patient_id,
              (p.gender)::public.gender_enum AS patient_gender,
              p.id AS visit_id,
              'Registration'::text AS visit_type,
              p.registration_facility_id AS facility_id,
              p.registration_user_id AS user_id,
              p.recorded_at AS visited_at,
              (EXTRACT(doy FROM ((p.recorded_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year
            FROM public.patients p
            WHERE ((p.deleted_at IS NULL) AND (p.recorded_at > (CURRENT_TIMESTAMP - '30 days'::interval)))
          ), all_follow_ups AS (
          SELECT follow_up_blood_pressures.patient_id,
              follow_up_blood_pressures.patient_gender,
              follow_up_blood_pressures.visit_id,
              follow_up_blood_pressures.visit_type,
              follow_up_blood_pressures.facility_id,
              follow_up_blood_pressures.user_id,
              follow_up_blood_pressures.visited_at,
              follow_up_blood_pressures.day_of_year
            FROM follow_up_blood_pressures
          UNION
          SELECT follow_up_blood_sugars.patient_id,
              follow_up_blood_sugars.patient_gender,
              follow_up_blood_sugars.visit_id,
              follow_up_blood_sugars.visit_type,
              follow_up_blood_sugars.facility_id,
              follow_up_blood_sugars.user_id,
              follow_up_blood_sugars.visited_at,
              follow_up_blood_sugars.day_of_year
            FROM follow_up_blood_sugars
          UNION
          SELECT follow_up_prescription_drugs.patient_id,
              follow_up_prescription_drugs.patient_gender,
              follow_up_prescription_drugs.visit_id,
              follow_up_prescription_drugs.visit_type,
              follow_up_prescription_drugs.facility_id,
              follow_up_prescription_drugs.user_id,
              follow_up_prescription_drugs.visited_at,
              follow_up_prescription_drugs.day_of_year
            FROM follow_up_prescription_drugs
          UNION
          SELECT follow_up_appointments.patient_id,
              follow_up_appointments.patient_gender,
              follow_up_appointments.visit_id,
              follow_up_appointments.visit_type,
              follow_up_appointments.facility_id,
              follow_up_appointments.user_id,
              follow_up_appointments.visited_at,
              follow_up_appointments.day_of_year
            FROM follow_up_appointments
          ), all_follow_ups_with_medical_histories AS (
          SELECT DISTINCT ON (all_follow_ups.day_of_year, all_follow_ups.facility_id, all_follow_ups.patient_id) all_follow_ups.patient_id,
              all_follow_ups.patient_gender,
              all_follow_ups.facility_id,
              mh.diabetes,
              mh.hypertension,
              all_follow_ups.user_id,
              all_follow_ups.visit_id,
              all_follow_ups.visit_type,
              all_follow_ups.visited_at,
              all_follow_ups.day_of_year
            FROM (all_follow_ups
              JOIN public.medical_histories mh ON ((all_follow_ups.patient_id = mh.patient_id)))
          ), registered_patients_with_medical_histories AS (
          SELECT DISTINCT ON (registered_patients.day_of_year, registered_patients.facility_id, registered_patients.patient_id) registered_patients.patient_id,
              registered_patients.patient_gender,
              registered_patients.facility_id,
              mh.diabetes,
              mh.hypertension,
              registered_patients.user_id,
              registered_patients.visit_id,
              registered_patients.visit_type,
              registered_patients.visited_at,
              registered_patients.day_of_year
            FROM (registered_patients
              JOIN public.medical_histories mh ON ((registered_patients.patient_id = mh.patient_id)))
          ), daily_registered_patients AS (
          SELECT DISTINCT ON (registered_patients_with_medical_histories.facility_id, (date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))) registered_patients_with_medical_histories.facility_id,
              date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) AS visit_date,
              registered_patients_with_medical_histories.day_of_year,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) OR (registered_patients_with_medical_histories.diabetes = 'yes'::text))) AS daily_registrations_htn_or_dm,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text))) AS daily_registrations_htn_and_dm,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) AS daily_registrations_htn_and_dm_female,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) AS daily_registrations_htn_and_dm_male,
              count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) AS daily_registrations_htn_and_dm_transgender,
              (count(*) FILTER (WHERE (registered_patients_with_medical_histories.hypertension = 'yes'::text)) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text)))) AS daily_registrations_htn_only,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_registrations_htn_only_female,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_registrations_htn_only_male,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_registrations_htn_only_transgender,
              (count(*) FILTER (WHERE (registered_patients_with_medical_histories.diabetes = 'yes'::text)) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text)))) AS daily_registrations_dm_only,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_registrations_dm_only_female,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_registrations_dm_only_male,
              (count(*) FILTER (WHERE ((registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((registered_patients_with_medical_histories.hypertension = 'yes'::text) AND (registered_patients_with_medical_histories.diabetes = 'yes'::text) AND (registered_patients_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_registrations_dm_only_transgender
            FROM registered_patients_with_medical_histories
            GROUP BY registered_patients_with_medical_histories.facility_id, (date(((registered_patients_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))), registered_patients_with_medical_histories.day_of_year
          ), daily_follow_ups AS (
          SELECT DISTINCT ON (all_follow_ups_with_medical_histories.facility_id, (date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))) all_follow_ups_with_medical_histories.facility_id,
              date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))) AS visit_date,
              all_follow_ups_with_medical_histories.day_of_year,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) OR (all_follow_ups_with_medical_histories.diabetes = 'yes'::text))) AS daily_follow_ups_htn_or_dm,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text))) AS daily_follow_ups_htn_and_dm,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_female,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_male,
              count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) AS daily_follow_ups_htn_and_dm_transgender,
              (count(*) FILTER (WHERE (all_follow_ups_with_medical_histories.hypertension = 'yes'::text)) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)))) AS daily_follow_ups_htn_only,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_follow_ups_htn_only_female,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_follow_ups_htn_only_male,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_follow_ups_htn_only_transgender,
              (count(*) FILTER (WHERE (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text)))) AS daily_follow_ups_dm_only,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'female'::public.gender_enum)))) AS daily_follow_ups_dm_only_female,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'male'::public.gender_enum)))) AS daily_follow_ups_dm_only_male,
              (count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum))) - count(*) FILTER (WHERE ((all_follow_ups_with_medical_histories.hypertension = 'yes'::text) AND (all_follow_ups_with_medical_histories.diabetes = 'yes'::text) AND (all_follow_ups_with_medical_histories.patient_gender = 'transgender'::public.gender_enum)))) AS daily_follow_ups_dm_only_transgender
            FROM all_follow_ups_with_medical_histories
            GROUP BY all_follow_ups_with_medical_histories.facility_id, (date(((all_follow_ups_with_medical_histories.visited_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)))), all_follow_ups_with_medical_histories.day_of_year
          ), last_30_days AS (
          SELECT (generate_series((CURRENT_TIMESTAMP - '30 days'::interval), CURRENT_TIMESTAMP, '1 day'::interval))::date AS date
          )
        SELECT rf.facility_region_slug,
            rf.facility_id,
            rf.facility_region_id,
            rf.block_region_id,
            rf.district_region_id,
            rf.state_region_id,
            last_30_days.date AS visit_date,
            (EXTRACT(doy FROM ((last_30_days.date AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting))))::integer AS day_of_year,
            COALESCE(daily_registered_patients.daily_registrations_htn_or_dm, (0)::bigint) AS daily_registrations_htn_or_dm,
            COALESCE(daily_registered_patients.daily_registrations_htn_only, (0)::bigint) AS daily_registrations_htn_only,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_male, (0)::bigint) AS daily_registrations_htn_only_male,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_female, (0)::bigint) AS daily_registrations_htn_only_female,
            COALESCE(daily_registered_patients.daily_registrations_htn_only_transgender, (0)::bigint) AS daily_registrations_htn_only_transgender,
            COALESCE(daily_registered_patients.daily_registrations_dm_only, (0)::bigint) AS daily_registrations_dm_only,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_male, (0)::bigint) AS daily_registrations_dm_only_male,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_female, (0)::bigint) AS daily_registrations_dm_only_female,
            COALESCE(daily_registered_patients.daily_registrations_dm_only_transgender, (0)::bigint) AS daily_registrations_dm_only_transgender,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm, (0)::bigint) AS daily_registrations_htn_and_dm,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_male, (0)::bigint) AS daily_registrations_htn_and_dm_male,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_female, (0)::bigint) AS daily_registrations_htn_and_dm_female,
            COALESCE(daily_registered_patients.daily_registrations_htn_and_dm_transgender, (0)::bigint) AS daily_registrations_htn_and_dm_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_or_dm, (0)::bigint) AS daily_follow_ups_htn_or_dm,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only, (0)::bigint) AS daily_follow_ups_htn_only,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_female, (0)::bigint) AS daily_follow_ups_htn_only_female,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_male, (0)::bigint) AS daily_follow_ups_htn_only_male,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_only_transgender, (0)::bigint) AS daily_follow_ups_htn_only_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only, (0)::bigint) AS daily_follow_ups_dm_only,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_female, (0)::bigint) AS daily_follow_ups_dm_only_female,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_male, (0)::bigint) AS daily_follow_ups_dm_only_male,
            COALESCE(daily_follow_ups.daily_follow_ups_dm_only_transgender, (0)::bigint) AS daily_follow_ups_dm_only_transgender,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm, (0)::bigint) AS daily_follow_ups_htn_and_dm,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_male, (0)::bigint) AS daily_follow_ups_htn_and_dm_male,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_female, (0)::bigint) AS daily_follow_ups_htn_and_dm_female,
            COALESCE(daily_follow_ups.daily_follow_ups_htn_and_dm_transgender, (0)::bigint) AS daily_follow_ups_htn_and_dm_transgender
          FROM (((public.reporting_facilities rf
            JOIN last_30_days ON (true))
            LEFT JOIN daily_registered_patients ON (((daily_registered_patients.visit_date = last_30_days.date) AND (daily_registered_patients.facility_id = rf.facility_id))))
            LEFT JOIN daily_follow_ups ON (((daily_follow_ups.visit_date = last_30_days.date) AND (daily_follow_ups.facility_id = rf.facility_id))))
          ORDER BY last_30_days.date DESC
          WITH NO DATA;
    SQL

    add_index :reporting_facility_daily_follow_ups_and_registrations, [:facility_id, :visit_date], name: "fd_far_facility_id_visit_date", unique: true
    add_index :reporting_facility_daily_follow_ups_and_registrations, [:facility_region_id, :visit_date], name: "index_df_facility_region_id_visit_date", unique: true
  end
end
