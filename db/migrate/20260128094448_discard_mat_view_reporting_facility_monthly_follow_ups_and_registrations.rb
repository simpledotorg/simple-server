class DiscardMatViewReportingFacilityMonthlyFollowUpsAndRegistrations < ActiveRecord::Migration[6.1]
  def up
    drop_view :reporting_facility_monthly_follow_ups_and_registrations, materialized: true

    execute <<~SQL
      CREATE VIEW public.reporting_facility_monthly_follow_ups_and_registrations AS SELECT * FROM simple_reporting.reporting_facility_monthly_follow_ups_and_registrations;
    SQL
  end

  def down
    drop_view :reporting_facility_monthly_follow_ups_and_registrations

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_monthly_follow_ups_and_registrations AS
      WITH monthly_registration_patient_states AS (
        SELECT reporting_patient_states.registration_facility_id AS facility_id,
          reporting_patient_states.month_date,
          reporting_patient_states.gender,
          reporting_patient_states.hypertension,
          reporting_patient_states.diabetes
          FROM public.reporting_patient_states
          WHERE (reporting_patient_states.months_since_registration = (0)::double precision)
        ), registered_patients AS (
        SELECT monthly_registration_patient_states.facility_id,
          monthly_registration_patient_states.month_date,
          count(*) AS monthly_registrations_all,
          count(*) FILTER (WHERE (monthly_registration_patient_states.hypertension = 'yes'::text)) AS monthly_registrations_htn_all,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) AS monthly_registrations_htn_female,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) AS monthly_registrations_htn_male,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) AS monthly_registrations_htn_transgender,
          count(*) FILTER (WHERE (monthly_registration_patient_states.diabetes = 'yes'::text)) AS monthly_registrations_dm_all,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) AS monthly_registrations_dm_female,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) AS monthly_registrations_dm_male,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) AS monthly_registrations_dm_transgender,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) OR (monthly_registration_patient_states.diabetes = 'yes'::text))) AS monthly_registrations_htn_or_dm,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text))) AS monthly_registrations_htn_and_dm,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) AS monthly_registrations_htn_and_dm_female,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) AS monthly_registrations_htn_and_dm_male,
          count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) AS monthly_registrations_htn_and_dm_transgender,
          (count(*) FILTER (WHERE (monthly_registration_patient_states.hypertension = 'yes'::text)) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text)))) AS monthly_registrations_htn_only,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text)))) AS monthly_registrations_htn_only_female,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text)))) AS monthly_registrations_htn_only_male,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text)))) AS monthly_registrations_htn_only_transgender,
          (count(*) FILTER (WHERE (monthly_registration_patient_states.diabetes = 'yes'::text)) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text)))) AS monthly_registrations_dm_only,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'female'::text)))) AS monthly_registrations_dm_only_female,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'male'::text)))) AS monthly_registrations_dm_only_male,
          (count(*) FILTER (WHERE ((monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text))) - count(*) FILTER (WHERE ((monthly_registration_patient_states.hypertension = 'yes'::text) AND (monthly_registration_patient_states.diabetes = 'yes'::text) AND ((monthly_registration_patient_states.gender)::text = 'transgender'::text)))) AS monthly_registrations_dm_only_transgender
          FROM monthly_registration_patient_states
        GROUP BY monthly_registration_patient_states.facility_id, monthly_registration_patient_states.month_date
        ), follow_ups AS (
        SELECT reporting_patient_follow_ups.facility_id,
          reporting_patient_follow_ups.month_date,
          count(DISTINCT reporting_patient_follow_ups.patient_id) AS monthly_follow_ups_all,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)) AS monthly_follow_ups_htn_all,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) AS monthly_follow_ups_htn_female,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) AS monthly_follow_ups_htn_male,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) AS monthly_follow_ups_htn_transgender,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.diabetes = 'yes'::text)) AS monthly_follow_ups_dm_all,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) AS monthly_follow_ups_dm_female,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) AS monthly_follow_ups_dm_male,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) AS monthly_follow_ups_dm_transgender,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) OR (reporting_patient_follow_ups.diabetes = 'yes'::text))) AS monthly_follow_ups_htn_or_dm,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text))) AS monthly_follow_ups_htn_and_dm,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) AS monthly_follow_ups_htn_and_dm_female,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) AS monthly_follow_ups_htn_and_dm_male,
          count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) AS monthly_follow_ups_htn_and_dm_transgender,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text)))) AS monthly_follow_ups_htn_only,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum)))) AS monthly_follow_ups_htn_only_female,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum)))) AS monthly_follow_ups_htn_only_male,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum)))) AS monthly_follow_ups_htn_only_transgender,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE (reporting_patient_follow_ups.diabetes = 'yes'::text)) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text)))) AS monthly_follow_ups_dm_only,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'female'::public.gender_enum)))) AS monthly_follow_ups_dm_only_female,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'male'::public.gender_enum)))) AS monthly_follow_ups_dm_only_male,
          (count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum))) - count(DISTINCT reporting_patient_follow_ups.patient_id) FILTER (WHERE ((reporting_patient_follow_ups.hypertension = 'yes'::text) AND (reporting_patient_follow_ups.diabetes = 'yes'::text) AND (reporting_patient_follow_ups.patient_gender = 'transgender'::public.gender_enum)))) AS monthly_follow_ups_dm_only_transgender
          FROM public.reporting_patient_follow_ups
        GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        )
      SELECT rf.facility_region_slug,
        rf.facility_id,
        rf.facility_region_id,
        rf.block_region_id,
        rf.district_region_id,
        rf.state_region_id,
        cal.month_date,
        COALESCE(registered_patients.monthly_registrations_all, (0)::bigint) AS monthly_registrations_all,
        COALESCE(registered_patients.monthly_registrations_htn_all, (0)::bigint) AS monthly_registrations_htn_all,
        COALESCE(registered_patients.monthly_registrations_htn_male, (0)::bigint) AS monthly_registrations_htn_male,
        COALESCE(registered_patients.monthly_registrations_htn_female, (0)::bigint) AS monthly_registrations_htn_female,
        COALESCE(registered_patients.monthly_registrations_htn_transgender, (0)::bigint) AS monthly_registrations_htn_transgender,
        COALESCE(registered_patients.monthly_registrations_dm_all, (0)::bigint) AS monthly_registrations_dm_all,
        COALESCE(registered_patients.monthly_registrations_dm_male, (0)::bigint) AS monthly_registrations_dm_male,
        COALESCE(registered_patients.monthly_registrations_dm_female, (0)::bigint) AS monthly_registrations_dm_female,
        COALESCE(registered_patients.monthly_registrations_dm_transgender, (0)::bigint) AS monthly_registrations_dm_transgender,
        COALESCE(follow_ups.monthly_follow_ups_all, (0)::bigint) AS monthly_follow_ups_all,
        COALESCE(follow_ups.monthly_follow_ups_htn_all, (0)::bigint) AS monthly_follow_ups_htn_all,
        COALESCE(follow_ups.monthly_follow_ups_htn_female, (0)::bigint) AS monthly_follow_ups_htn_female,
        COALESCE(follow_ups.monthly_follow_ups_htn_male, (0)::bigint) AS monthly_follow_ups_htn_male,
        COALESCE(follow_ups.monthly_follow_ups_htn_transgender, (0)::bigint) AS monthly_follow_ups_htn_transgender,
        COALESCE(follow_ups.monthly_follow_ups_dm_all, (0)::bigint) AS monthly_follow_ups_dm_all,
        COALESCE(follow_ups.monthly_follow_ups_dm_female, (0)::bigint) AS monthly_follow_ups_dm_female,
        COALESCE(follow_ups.monthly_follow_ups_dm_male, (0)::bigint) AS monthly_follow_ups_dm_male,
        COALESCE(follow_ups.monthly_follow_ups_dm_transgender, (0)::bigint) AS monthly_follow_ups_dm_transgender,
        COALESCE(registered_patients.monthly_registrations_htn_or_dm, (0)::bigint) AS monthly_registrations_htn_or_dm,
        COALESCE(registered_patients.monthly_registrations_htn_only, (0)::bigint) AS monthly_registrations_htn_only,
        COALESCE(registered_patients.monthly_registrations_htn_only_male, (0)::bigint) AS monthly_registrations_htn_only_male,
        COALESCE(registered_patients.monthly_registrations_htn_only_female, (0)::bigint) AS monthly_registrations_htn_only_female,
        COALESCE(registered_patients.monthly_registrations_htn_only_transgender, (0)::bigint) AS monthly_registrations_htn_only_transgender,
        COALESCE(registered_patients.monthly_registrations_dm_only, (0)::bigint) AS monthly_registrations_dm_only,
        COALESCE(registered_patients.monthly_registrations_dm_only_male, (0)::bigint) AS monthly_registrations_dm_only_male,
        COALESCE(registered_patients.monthly_registrations_dm_only_female, (0)::bigint) AS monthly_registrations_dm_only_female,
        COALESCE(registered_patients.monthly_registrations_dm_only_transgender, (0)::bigint) AS monthly_registrations_dm_only_transgender,
        COALESCE(registered_patients.monthly_registrations_htn_and_dm, (0)::bigint) AS monthly_registrations_htn_and_dm,
        COALESCE(registered_patients.monthly_registrations_htn_and_dm_male, (0)::bigint) AS monthly_registrations_htn_and_dm_male,
        COALESCE(registered_patients.monthly_registrations_htn_and_dm_female, (0)::bigint) AS monthly_registrations_htn_and_dm_female,
        COALESCE(registered_patients.monthly_registrations_htn_and_dm_transgender, (0)::bigint) AS monthly_registrations_htn_and_dm_transgender,
        COALESCE(follow_ups.monthly_follow_ups_htn_or_dm, (0)::bigint) AS monthly_follow_ups_htn_or_dm,
        COALESCE(follow_ups.monthly_follow_ups_htn_only, (0)::bigint) AS monthly_follow_ups_htn_only,
        COALESCE(follow_ups.monthly_follow_ups_htn_only_female, (0)::bigint) AS monthly_follow_ups_htn_only_female,
        COALESCE(follow_ups.monthly_follow_ups_htn_only_male, (0)::bigint) AS monthly_follow_ups_htn_only_male,
        COALESCE(follow_ups.monthly_follow_ups_htn_only_transgender, (0)::bigint) AS monthly_follow_ups_htn_only_transgender,
        COALESCE(follow_ups.monthly_follow_ups_dm_only, (0)::bigint) AS monthly_follow_ups_dm_only,
        COALESCE(follow_ups.monthly_follow_ups_dm_only_female, (0)::bigint) AS monthly_follow_ups_dm_only_female,
        COALESCE(follow_ups.monthly_follow_ups_dm_only_male, (0)::bigint) AS monthly_follow_ups_dm_only_male,
        COALESCE(follow_ups.monthly_follow_ups_dm_only_transgender, (0)::bigint) AS monthly_follow_ups_dm_only_transgender,
        COALESCE(follow_ups.monthly_follow_ups_htn_and_dm, (0)::bigint) AS monthly_follow_ups_htn_and_dm,
        COALESCE(follow_ups.monthly_follow_ups_htn_and_dm_male, (0)::bigint) AS monthly_follow_ups_htn_and_dm_male,
        COALESCE(follow_ups.monthly_follow_ups_htn_and_dm_female, (0)::bigint) AS monthly_follow_ups_htn_and_dm_female,
        COALESCE(follow_ups.monthly_follow_ups_htn_and_dm_transgender, (0)::bigint) AS monthly_follow_ups_htn_and_dm_transgender
      FROM (((public.reporting_facilities rf
        JOIN public.reporting_months cal ON (true))
        LEFT JOIN registered_patients ON (((registered_patients.month_date = cal.month_date) AND (registered_patients.facility_id = rf.facility_id))))
        LEFT JOIN follow_ups ON (((follow_ups.month_date = cal.month_date) AND (follow_ups.facility_id = rf.facility_id))))
      ORDER BY cal.month_date DESC
      WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX facility_monthly_fr_facility_id ON public.reporting_facility_monthly_follow_ups_and_registrations USING btree (facility_id);
      CREATE INDEX facility_monthly_fr_facility_region_id ON public.reporting_facility_monthly_follow_ups_and_registrations USING btree (facility_region_id);
      CREATE UNIQUE INDEX facility_monthly_fr_month_date_facility_region_id ON public.reporting_facility_monthly_follow_ups_and_registrations USING btree (month_date, facility_region_id);
    SQL
  end
end
