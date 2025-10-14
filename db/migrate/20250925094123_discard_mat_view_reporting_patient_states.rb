class DiscardMatViewReportingPatientStates < ActiveRecord::Migration[6.1]
  def up
    drop_view :reporting_quarterly_facility_states, materialized: true
    drop_view :reporting_facility_states, materialized: true
    drop_view :reporting_overdue_patients, materialized: true
    drop_view :reporting_facility_monthly_follow_ups_and_registrations, materialized: true
    drop_view :reporting_patient_states, materialized: true
    execute <<~SQL
      CREATE VIEW public.reporting_patient_states AS SELECT * FROM simple_reporting.reporting_patient_states;
    SQL

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

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_overdue_patients AS
      WITH patients_with_appointments AS (
      SELECT DISTINCT ON (rps.patient_id, rps.month_date) rps.month_date,
        rps.patient_id,
        rps.hypertension,
        rps.diabetes,
        rps.htn_care_state,
        rps.month,
        rps.quarter,
        rps.year,
        rps.month_string,
        rps.quarter_string,
        rps.assigned_facility_id,
        rps.assigned_facility_slug,
        rps.assigned_facility_region_id,
        rps.assigned_block_slug,
        rps.assigned_block_region_id,
        rps.assigned_district_slug,
        rps.assigned_district_region_id,
        rps.assigned_state_slug,
        rps.assigned_state_region_id,
        rps.assigned_organization_slug,
        rps.assigned_organization_region_id,
        appointments.id AS previous_appointment_id,
        appointments.device_created_at AS previous_appointment_date,
        appointments.scheduled_date AS previous_appointment_schedule_date
        FROM (public.reporting_patient_states rps
          LEFT JOIN public.appointments ON (((appointments.patient_id = rps.patient_id) AND (appointments.device_created_at < rps.month_date))))
        WHERE (((rps.status)::text <> 'dead'::text) AND (rps.month_date > (now() - '2 years'::interval)))
        ORDER BY rps.patient_id, rps.month_date, appointments.device_created_at DESC
        ), patients_with_appointments_and_visits AS (
        SELECT patients_with_appointments.month_date,
          patients_with_appointments.patient_id,
          patients_with_appointments.hypertension,
          patients_with_appointments.diabetes,
          patients_with_appointments.htn_care_state,
          patients_with_appointments.month,
          patients_with_appointments.quarter,
          patients_with_appointments.year,
          patients_with_appointments.month_string,
          patients_with_appointments.quarter_string,
          patients_with_appointments.assigned_facility_id,
          patients_with_appointments.assigned_facility_slug,
          patients_with_appointments.assigned_facility_region_id,
          patients_with_appointments.assigned_block_slug,
          patients_with_appointments.assigned_block_region_id,
          patients_with_appointments.assigned_district_slug,
          patients_with_appointments.assigned_district_region_id,
          patients_with_appointments.assigned_state_slug,
          patients_with_appointments.assigned_state_region_id,
          patients_with_appointments.assigned_organization_slug,
          patients_with_appointments.assigned_organization_region_id,
          patients_with_appointments.previous_appointment_id,
          patients_with_appointments.previous_appointment_date,
          patients_with_appointments.previous_appointment_schedule_date,
          visits.visit_id,
          visits.visited_at_after_appointment
        FROM (patients_with_appointments
          LEFT JOIN LATERAL ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id AS visit_id,
                blood_sugars.patient_id,
                blood_sugars.recorded_at AS visited_at_after_appointment
                FROM public.blood_sugars
              WHERE ((blood_sugars.deleted_at IS NULL) AND (blood_sugars.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < blood_sugars.recorded_at) AND (blood_sugars.recorded_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT blood_pressures.id AS visit_id,
                blood_pressures.patient_id,
                blood_pressures.recorded_at AS visited_at_after_appointment
                FROM public.blood_pressures
              WHERE ((blood_pressures.deleted_at IS NULL) AND (blood_pressures.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < blood_pressures.recorded_at) AND (blood_pressures.recorded_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT patients_with_appointments_visit.id AS visit_id,
                patients_with_appointments_visit.patient_id,
                patients_with_appointments_visit.device_created_at AS visited_at_after_appointment
                FROM public.appointments patients_with_appointments_visit
              WHERE ((patients_with_appointments_visit.deleted_at IS NULL) AND (patients_with_appointments_visit.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < patients_with_appointments_visit.device_created_at) AND (patients_with_appointments_visit.device_created_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT prescription_drugs.id AS visit_id,
                prescription_drugs.patient_id,
                prescription_drugs.device_created_at AS visited_at_after_appointment
                FROM public.prescription_drugs
              WHERE ((prescription_drugs.deleted_at IS NULL) AND (prescription_drugs.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < prescription_drugs.device_created_at) AND (prescription_drugs.device_created_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
          ORDER BY 2, 3) visits ON ((patients_with_appointments.patient_id = visits.patient_id)))
        ), patient_with_call_results AS (
         SELECT DISTINCT ON (patients_with_appointments_and_visits.patient_id, patients_with_appointments_and_visits.month_date) patients_with_appointments_and_visits.month_date,
            patients_with_appointments_and_visits.patient_id,
            patients_with_appointments_and_visits.hypertension,
            patients_with_appointments_and_visits.diabetes,
            patients_with_appointments_and_visits.htn_care_state,
            patients_with_appointments_and_visits.month,
            patients_with_appointments_and_visits.quarter,
            patients_with_appointments_and_visits.year,
            patients_with_appointments_and_visits.month_string,
            patients_with_appointments_and_visits.quarter_string,
            patients_with_appointments_and_visits.assigned_facility_id,
            patients_with_appointments_and_visits.assigned_facility_slug,
            patients_with_appointments_and_visits.assigned_facility_region_id,
            patients_with_appointments_and_visits.assigned_block_slug,
            patients_with_appointments_and_visits.assigned_block_region_id,
            patients_with_appointments_and_visits.assigned_district_slug,
            patients_with_appointments_and_visits.assigned_district_region_id,
            patients_with_appointments_and_visits.assigned_state_slug,
            patients_with_appointments_and_visits.assigned_state_region_id,
            patients_with_appointments_and_visits.assigned_organization_slug,
            patients_with_appointments_and_visits.assigned_organization_region_id,
            patients_with_appointments_and_visits.previous_appointment_id,
            patients_with_appointments_and_visits.previous_appointment_date,
            patients_with_appointments_and_visits.previous_appointment_schedule_date,
            patients_with_appointments_and_visits.visit_id,
            patients_with_appointments_and_visits.visited_at_after_appointment,
            ((previous_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE 'UTC'::text) AS previous_called_at,
            previous_call_results.result_type AS previous_call_result_type,
            previous_call_results.remove_reason AS previous_call_removed_from_overdue_list_reason,
            ((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE 'UTC'::text) AS next_called_at,
            next_call_results.result_type AS next_call_result_type,
            next_call_results.remove_reason AS next_call_removed_from_overdue_list_reason,
            next_call_results.user_id AS called_by_user_id
           FROM ((patients_with_appointments_and_visits
             LEFT JOIN public.call_results previous_call_results ON (((patients_with_appointments_and_visits.patient_id = previous_call_results.patient_id) AND (((previous_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) < patients_with_appointments_and_visits.month_date) AND (previous_call_results.device_created_at > patients_with_appointments_and_visits.previous_appointment_schedule_date))))
             LEFT JOIN public.call_results next_call_results ON (((patients_with_appointments_and_visits.patient_id = next_call_results.patient_id) AND (((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) >= patients_with_appointments_and_visits.month_date) AND (((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) < (patients_with_appointments_and_visits.month_date + '1 mon'::interval)))))
          ORDER BY patients_with_appointments_and_visits.patient_id, patients_with_appointments_and_visits.month_date, next_call_results.device_created_at, previous_call_results.device_created_at DESC
        ), patient_with_call_results_and_phone AS (
         SELECT DISTINCT ON (patient_with_call_results.patient_id, patient_with_call_results.month_date) patient_with_call_results.month_date,
            patient_with_call_results.patient_id,
            patient_with_call_results.hypertension,
            patient_with_call_results.diabetes,
            patient_with_call_results.htn_care_state,
            patient_with_call_results.month,
            patient_with_call_results.quarter,
            patient_with_call_results.year,
            patient_with_call_results.month_string,
            patient_with_call_results.quarter_string,
            patient_with_call_results.assigned_facility_id,
            patient_with_call_results.assigned_facility_slug,
            patient_with_call_results.assigned_facility_region_id,
            patient_with_call_results.assigned_block_slug,
            patient_with_call_results.assigned_block_region_id,
            patient_with_call_results.assigned_district_slug,
            patient_with_call_results.assigned_district_region_id,
            patient_with_call_results.assigned_state_slug,
            patient_with_call_results.assigned_state_region_id,
            patient_with_call_results.assigned_organization_slug,
            patient_with_call_results.assigned_organization_region_id,
            patient_with_call_results.previous_appointment_id,
            patient_with_call_results.previous_appointment_date,
            patient_with_call_results.previous_appointment_schedule_date,
            patient_with_call_results.visit_id,
            patient_with_call_results.visited_at_after_appointment,
            patient_with_call_results.previous_called_at,
            patient_with_call_results.previous_call_result_type,
            patient_with_call_results.previous_call_removed_from_overdue_list_reason,
            patient_with_call_results.next_called_at,
            patient_with_call_results.next_call_result_type,
            patient_with_call_results.next_call_removed_from_overdue_list_reason,
            patient_with_call_results.called_by_user_id,
            patient_phone_numbers.number AS patient_phone_number
           FROM (patient_with_call_results
             LEFT JOIN public.patient_phone_numbers ON ((patient_phone_numbers.patient_id = patient_with_call_results.patient_id)))
          ORDER BY patient_with_call_results.patient_id, patient_with_call_results.month_date
        )
      SELECT patient_with_call_results_and_phone.month_date,
        patient_with_call_results_and_phone.patient_id,
        patient_with_call_results_and_phone.hypertension,
        patient_with_call_results_and_phone.diabetes,
        patient_with_call_results_and_phone.htn_care_state,
        patient_with_call_results_and_phone.month,
        patient_with_call_results_and_phone.quarter,
        patient_with_call_results_and_phone.year,
        patient_with_call_results_and_phone.month_string,
        patient_with_call_results_and_phone.quarter_string,
        patient_with_call_results_and_phone.assigned_facility_id,
        patient_with_call_results_and_phone.assigned_facility_slug,
        patient_with_call_results_and_phone.assigned_facility_region_id,
        patient_with_call_results_and_phone.assigned_block_slug,
        patient_with_call_results_and_phone.assigned_block_region_id,
        patient_with_call_results_and_phone.assigned_district_slug,
        patient_with_call_results_and_phone.assigned_district_region_id,
        patient_with_call_results_and_phone.assigned_state_slug,
        patient_with_call_results_and_phone.assigned_state_region_id,
        patient_with_call_results_and_phone.assigned_organization_slug,
        patient_with_call_results_and_phone.assigned_organization_region_id,
        patient_with_call_results_and_phone.previous_appointment_id,
        patient_with_call_results_and_phone.previous_appointment_date,
        patient_with_call_results_and_phone.previous_appointment_schedule_date,
        patient_with_call_results_and_phone.visited_at_after_appointment,
        patient_with_call_results_and_phone.called_by_user_id,
        patient_with_call_results_and_phone.next_called_at,
        patient_with_call_results_and_phone.previous_called_at,
        patient_with_call_results_and_phone.next_call_result_type,
        patient_with_call_results_and_phone.next_call_removed_from_overdue_list_reason,
        patient_with_call_results_and_phone.previous_call_result_type,
        patient_with_call_results_and_phone.previous_call_removed_from_overdue_list_reason,
            CASE
                WHEN (patient_with_call_results_and_phone.previous_appointment_id IS NULL) THEN 'no'::text
                WHEN (patient_with_call_results_and_phone.previous_appointment_schedule_date >= patient_with_call_results_and_phone.month_date) THEN 'no'::text
                WHEN ((patient_with_call_results_and_phone.previous_appointment_schedule_date < patient_with_call_results_and_phone.month_date) AND (patient_with_call_results_and_phone.visited_at_after_appointment < patient_with_call_results_and_phone.month_date)) THEN 'no'::text
                ELSE 'yes'::text
            END AS is_overdue,
            CASE
                WHEN (patient_with_call_results_and_phone.next_called_at IS NULL) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_called,
            CASE
                WHEN ((patient_with_call_results_and_phone.visited_at_after_appointment IS NULL) OR (patient_with_call_results_and_phone.next_called_at IS NULL)) THEN 'no'::text
                WHEN (patient_with_call_results_and_phone.visited_at_after_appointment > (patient_with_call_results_and_phone.next_called_at + '15 days'::interval)) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_visited_following_call,
            CASE
                WHEN (patient_with_call_results_and_phone.htn_care_state = 'lost_to_follow_up'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS ltfu,
            CASE
                WHEN (patient_with_call_results_and_phone.htn_care_state = 'under_care'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS under_care,
            CASE
                WHEN (patient_with_call_results_and_phone.patient_phone_number IS NULL) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_phone,
            CASE
                WHEN ((patient_with_call_results_and_phone.previous_call_result_type)::text = 'removed_from_overdue_list'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS removed_from_overdue_list,
            CASE
                WHEN ((patient_with_call_results_and_phone.next_call_result_type)::text = 'removed_from_overdue_list'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS removed_from_overdue_list_during_the_month
      FROM patient_with_call_results_and_phone
      WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX overdue_patients_assigned_facility_region_id ON public.reporting_overdue_patients USING btree (assigned_facility_region_id);
      CREATE UNIQUE INDEX overdue_patients_month_date_patient_id ON public.reporting_overdue_patients USING btree (month_date, patient_id);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_states AS
      WITH registered_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_registrations
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), registered_diabetes_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_diabetes_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_diabetes_registrations
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.diabetes = 'yes'::text)
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), registered_hypertension_and_diabetes_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_hypertension_and_diabetes_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_hypertension_and_diabetes_registrations
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.diabetes = 'yes'::text))
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), assigned_patients AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS dead,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state <> 'dead'::text)) AS cumulative_assigned_patients
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), assigned_diabetes_patients AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS diabetes_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS diabetes_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS diabetes_dead,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state <> 'dead'::text)) AS cumulative_assigned_diabetic_patients
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.diabetes = 'yes'::text)
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), adjusted_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'controlled'::text))) AS controlled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'uncontrolled'::text))) AS uncontrolled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS patients_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS patients_lost_to_follow_up
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), adjusted_diabetes_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text))) AS bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text))) AS bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text))) AS bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS bs_missed_visit_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'visited_no_bs'::text))) AS visited_no_bs_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS bs_missed_visit_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS diabetes_patients_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS diabetes_patients_lost_to_follow_up
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.diabetes = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration = (2)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_overdue_calls AS (
         SELECT reporting_overdue_calls.appointment_facility_region_id AS region_id,
            reporting_overdue_calls.month_date,
            count(DISTINCT reporting_overdue_calls.appointment_id) AS call_results
           FROM public.reporting_overdue_calls
          GROUP BY reporting_overdue_calls.appointment_facility_region_id, reporting_overdue_calls.month_date
        ), monthly_follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS follow_ups
           FROM public.reporting_patient_follow_ups
          WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        ), monthly_diabetes_follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS follow_ups
           FROM public.reporting_patient_follow_ups
          WHERE (reporting_patient_follow_ups.diabetes = 'yes'::text)
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        ), monthly_hypertension_overdue_patients AS (
         SELECT reporting_overdue_patients.assigned_facility_region_id,
            reporting_overdue_patients.month_date,
            count(*) FILTER (WHERE (reporting_overdue_patients.is_overdue = 'yes'::text)) AS overdue_patients,
            count(*) FILTER (WHERE ((reporting_overdue_patients.is_overdue = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_overdue_patients,
            count(*) FILTER (WHERE (reporting_overdue_patients.has_called = 'yes'::text)) AS patients_called,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS patients_called_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS patients_called_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS patients_called_with_result_removed_from_list,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_patients_called,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS contactable_patients_called_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS contactable_patients_called_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS contactable_patients_called_with_result_removed_from_list,
            count(*) FILTER (WHERE (reporting_overdue_patients.has_visited_following_call = 'yes'::text)) AS patients_returned_after_call,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS patients_returned_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS patients_returned_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS patients_returned_with_result_removed_from_list,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_patients_returned_after_call,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS contactable_patients_returned_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS contactable_patients_returned_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS contactable_patients_returned_with_result_removed_from_list
           FROM public.reporting_overdue_patients
          WHERE ((reporting_overdue_patients.hypertension = 'yes'::text) AND (reporting_overdue_patients.under_care = 'yes'::text))
          GROUP BY reporting_overdue_patients.assigned_facility_region_id, reporting_overdue_patients.month_date
        )
      SELECT cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string,
          rf.facility_id,
          rf.facility_name,
          rf.facility_type,
          rf.facility_size,
          rf.facility_region_id,
          rf.facility_region_name,
          rf.facility_region_slug,
          rf.block_region_id,
          rf.block_name,
          rf.block_slug,
          rf.district_id,
          rf.district_region_id,
          rf.district_name,
          rf.district_slug,
          rf.state_region_id,
          rf.state_name,
          rf.state_slug,
          rf.organization_id,
          rf.organization_region_id,
          rf.organization_name,
          rf.organization_slug,
          registered_patients.cumulative_registrations,
          registered_patients.monthly_registrations,
          registered_diabetes_patients.cumulative_diabetes_registrations,
          registered_diabetes_patients.monthly_diabetes_registrations,
          registered_hypertension_and_diabetes_patients.cumulative_hypertension_and_diabetes_registrations,
          registered_hypertension_and_diabetes_patients.monthly_hypertension_and_diabetes_registrations,
          assigned_patients.under_care,
          assigned_patients.lost_to_follow_up,
          assigned_patients.dead,
          assigned_patients.cumulative_assigned_patients,
          assigned_diabetes_patients.diabetes_under_care,
          assigned_diabetes_patients.diabetes_lost_to_follow_up,
          assigned_diabetes_patients.diabetes_dead,
          assigned_diabetes_patients.cumulative_assigned_diabetic_patients,
          adjusted_outcomes.controlled_under_care AS adjusted_controlled_under_care,
          adjusted_outcomes.uncontrolled_under_care AS adjusted_uncontrolled_under_care,
          adjusted_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
          adjusted_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,
          adjusted_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
          adjusted_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,
          adjusted_outcomes.patients_under_care AS adjusted_patients_under_care,
          adjusted_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,
          adjusted_diabetes_outcomes.random_bs_below_200_under_care AS adjusted_random_bs_below_200_under_care,
          adjusted_diabetes_outcomes.fasting_bs_below_200_under_care AS adjusted_fasting_bs_below_200_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_below_200_under_care AS adjusted_post_prandial_bs_below_200_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_below_200_under_care AS adjusted_hba1c_bs_below_200_under_care,
          adjusted_diabetes_outcomes.bs_below_200_under_care AS adjusted_bs_below_200_under_care,
          adjusted_diabetes_outcomes.random_bs_200_to_300_under_care AS adjusted_random_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.fasting_bs_200_to_300_under_care AS adjusted_fasting_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_200_to_300_under_care AS adjusted_post_prandial_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_200_to_300_under_care AS adjusted_hba1c_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.bs_200_to_300_under_care AS adjusted_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.random_bs_over_300_under_care AS adjusted_random_bs_over_300_under_care,
          adjusted_diabetes_outcomes.fasting_bs_over_300_under_care AS adjusted_fasting_bs_over_300_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_over_300_under_care AS adjusted_post_prandial_bs_over_300_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_over_300_under_care AS adjusted_hba1c_bs_over_300_under_care,
          adjusted_diabetes_outcomes.bs_over_300_under_care AS adjusted_bs_over_300_under_care,
          adjusted_diabetes_outcomes.bs_missed_visit_under_care AS adjusted_bs_missed_visit_under_care,
          adjusted_diabetes_outcomes.visited_no_bs_under_care AS adjusted_visited_no_bs_under_care,
          adjusted_diabetes_outcomes.bs_missed_visit_lost_to_follow_up AS adjusted_bs_missed_visit_lost_to_follow_up,
          adjusted_diabetes_outcomes.diabetes_patients_under_care AS adjusted_diabetes_patients_under_care,
          adjusted_diabetes_outcomes.diabetes_patients_lost_to_follow_up AS adjusted_diabetes_patients_lost_to_follow_up,
          monthly_cohort_outcomes.controlled AS monthly_cohort_controlled,
          monthly_cohort_outcomes.uncontrolled AS monthly_cohort_uncontrolled,
          monthly_cohort_outcomes.missed_visit AS monthly_cohort_missed_visit,
          monthly_cohort_outcomes.visited_no_bp AS monthly_cohort_visited_no_bp,
          monthly_cohort_outcomes.patients AS monthly_cohort_patients,
          monthly_overdue_calls.call_results AS monthly_overdue_calls,
          monthly_follow_ups.follow_ups AS monthly_follow_ups,
          monthly_diabetes_follow_ups.follow_ups AS monthly_diabetes_follow_ups,
          reporting_facility_appointment_scheduled_days.htn_total_appts_scheduled AS total_appts_scheduled,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_0_to_14_days AS appts_scheduled_0_to_14_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_15_to_31_days AS appts_scheduled_15_to_31_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_32_to_62_days AS appts_scheduled_32_to_62_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_more_than_62_days AS appts_scheduled_more_than_62_days,
          reporting_facility_appointment_scheduled_days.diabetes_total_appts_scheduled,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_0_to_14_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_15_to_31_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_32_to_62_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_more_than_62_days,
          monthly_hypertension_overdue_patients.overdue_patients,
          monthly_hypertension_overdue_patients.contactable_overdue_patients,
          monthly_hypertension_overdue_patients.patients_called,
          monthly_hypertension_overdue_patients.contactable_patients_called,
          monthly_hypertension_overdue_patients.patients_called_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.patients_called_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.patients_called_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.patients_returned_after_call,
          monthly_hypertension_overdue_patients.contactable_patients_returned_after_call,
          monthly_hypertension_overdue_patients.patients_returned_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.patients_returned_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.patients_returned_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_removed_from_list
        FROM ((((((((((((((public.reporting_facilities rf
          JOIN public.reporting_months cal ON (true))
          LEFT JOIN registered_patients ON (((registered_patients.month_date = cal.month_date) AND (registered_patients.region_id = rf.facility_region_id))))
          LEFT JOIN registered_diabetes_patients ON (((registered_diabetes_patients.month_date = cal.month_date) AND (registered_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN registered_hypertension_and_diabetes_patients ON (((registered_hypertension_and_diabetes_patients.month_date = cal.month_date) AND (registered_hypertension_and_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN assigned_patients ON (((assigned_patients.month_date = cal.month_date) AND (assigned_patients.region_id = rf.facility_region_id))))
          LEFT JOIN assigned_diabetes_patients ON (((assigned_diabetes_patients.month_date = cal.month_date) AND (assigned_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN adjusted_outcomes ON (((adjusted_outcomes.month_date = cal.month_date) AND (adjusted_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN adjusted_diabetes_outcomes ON (((adjusted_diabetes_outcomes.month_date = cal.month_date) AND (adjusted_diabetes_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_cohort_outcomes ON (((monthly_cohort_outcomes.month_date = cal.month_date) AND (monthly_cohort_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_overdue_calls ON (((monthly_overdue_calls.month_date = cal.month_date) AND (monthly_overdue_calls.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_follow_ups ON (((monthly_follow_ups.month_date = cal.month_date) AND (monthly_follow_ups.facility_id = rf.facility_id))))
          LEFT JOIN monthly_diabetes_follow_ups ON (((monthly_diabetes_follow_ups.month_date = cal.month_date) AND (monthly_diabetes_follow_ups.facility_id = rf.facility_id))))
          LEFT JOIN public.reporting_facility_appointment_scheduled_days ON (((reporting_facility_appointment_scheduled_days.month_date = cal.month_date) AND (reporting_facility_appointment_scheduled_days.facility_id = rf.facility_id))))
          LEFT JOIN monthly_hypertension_overdue_patients ON (((monthly_hypertension_overdue_patients.month_date = cal.month_date) AND (monthly_hypertension_overdue_patients.assigned_facility_region_id = rf.facility_region_id))))
        WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX index_fs_block_month_date ON public.reporting_facility_states USING btree (block_region_id, month_date);
      CREATE INDEX index_fs_district_month_date ON public.reporting_facility_states USING btree (district_region_id, month_date);
      CREATE UNIQUE INDEX index_fs_month_date_region_id ON public.reporting_facility_states USING btree (month_date, facility_region_id);
      CREATE INDEX index_fs_organization_month_date ON public.reporting_facility_states USING btree (organization_region_id, month_date);
      CREATE INDEX index_fs_state_month_date ON public.reporting_facility_states USING btree (state_region_id, month_date);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_quarterly_facility_states AS
      WITH quarterly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.quarter_string,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND ((((reporting_patient_states.month)::integer % 3) = 0) OR (reporting_patient_states.month_string = to_char(now(), 'YYYY-MM'::text))) AND (reporting_patient_states.quarters_since_registration = (1)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.quarter_string
        )
      SELECT cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string,
          rf.facility_id,
          rf.facility_name,
          rf.facility_type,
          rf.facility_size,
          rf.facility_region_id,
          rf.facility_region_name,
          rf.facility_region_slug,
          rf.block_region_id,
          rf.block_name,
          rf.block_slug,
          rf.district_id,
          rf.district_region_id,
          rf.district_name,
          rf.district_slug,
          rf.state_region_id,
          rf.state_name,
          rf.state_slug,
          rf.organization_id,
          rf.organization_region_id,
          rf.organization_name,
          rf.organization_slug,
          quarterly_cohort_outcomes.controlled AS quarterly_cohort_controlled,
          quarterly_cohort_outcomes.uncontrolled AS quarterly_cohort_uncontrolled,
          quarterly_cohort_outcomes.missed_visit AS quarterly_cohort_missed_visit,
          quarterly_cohort_outcomes.visited_no_bp AS quarterly_cohort_visited_no_bp,
          quarterly_cohort_outcomes.patients AS quarterly_cohort_patients
        FROM ((public.reporting_facilities rf
          JOIN public.reporting_months cal ON (((((cal.month)::integer % 3) = 0) OR (cal.month_string = to_char(now(), 'YYYY-MM'::text)))))
          LEFT JOIN quarterly_cohort_outcomes ON (((quarterly_cohort_outcomes.quarter_string = cal.quarter_string) AND (quarterly_cohort_outcomes.region_id = rf.facility_region_id))))
        WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX index_qfs_facility_id ON public.reporting_quarterly_facility_states USING btree (facility_id);
      CREATE UNIQUE INDEX index_qfs_quarter_string_region_id ON public.reporting_quarterly_facility_states USING btree (quarter_string, facility_region_id);
    SQL
  end

  def down
    drop_view :reporting_quarterly_facility_states, materialized: true
    drop_view :reporting_facility_states, materialized: true
    drop_view :reporting_overdue_patients, materialized: true
    drop_view :reporting_facility_monthly_follow_ups_and_registrations, materialized: true
    drop_view :reporting_patient_states

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_patient_states AS
        SELECT DISTINCT ON (p.id, cal.month_date) p.id AS patient_id,
          timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS recorded_at,
          p.status,
          p.gender,
          p.age,
          timezone('UTC'::text, timezone('UTC'::text, p.age_updated_at)) AS age_updated_at,
          p.date_of_birth,
          date_part('year'::text, COALESCE(age((p.date_of_birth)::timestamp with time zone), (make_interval(years => p.age) + age(p.age_updated_at)))) AS current_age,
          cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string,
          mh.hypertension,
          mh.prior_heart_attack,
          mh.prior_stroke,
          mh.chronic_kidney_disease,
          mh.receiving_treatment_for_hypertension,
          mh.diabetes,
          p.assigned_facility_id,
          assigned_facility.facility_size AS assigned_facility_size,
          assigned_facility.facility_type AS assigned_facility_type,
          assigned_facility.facility_region_slug AS assigned_facility_slug,
          assigned_facility.facility_region_id AS assigned_facility_region_id,
          assigned_facility.block_slug AS assigned_block_slug,
          assigned_facility.block_region_id AS assigned_block_region_id,
          assigned_facility.district_slug AS assigned_district_slug,
          assigned_facility.district_region_id AS assigned_district_region_id,
          assigned_facility.state_slug AS assigned_state_slug,
          assigned_facility.state_region_id AS assigned_state_region_id,
          assigned_facility.organization_slug AS assigned_organization_slug,
          assigned_facility.organization_region_id AS assigned_organization_region_id,
          p.registration_facility_id,
          registration_facility.facility_size AS registration_facility_size,
          registration_facility.facility_type AS registration_facility_type,
          registration_facility.facility_region_slug AS registration_facility_slug,
          registration_facility.facility_region_id AS registration_facility_region_id,
          registration_facility.block_slug AS registration_block_slug,
          registration_facility.block_region_id AS registration_block_region_id,
          registration_facility.district_slug AS registration_district_slug,
          registration_facility.district_region_id AS registration_district_region_id,
          registration_facility.state_slug AS registration_state_slug,
          registration_facility.state_region_id AS registration_state_region_id,
          registration_facility.organization_slug AS registration_organization_slug,
          registration_facility.organization_region_id AS registration_organization_region_id,
          bps.blood_pressure_id,
          bps.blood_pressure_facility_id AS bp_facility_id,
          bps.blood_pressure_recorded_at AS bp_recorded_at,
          bps.systolic,
          bps.diastolic,
          bss.blood_sugar_id,
          bss.blood_sugar_facility_id AS bs_facility_id,
          bss.blood_sugar_recorded_at AS bs_recorded_at,
          bss.blood_sugar_type,
          bss.blood_sugar_value,
          bss.blood_sugar_risk_state,
          visits.encounter_id,
          visits.encounter_recorded_at,
          visits.prescription_drug_id,
          visits.prescription_drug_recorded_at,
          visits.appointment_id,
          visits.appointment_recorded_at,
          visits.visited_facility_ids,
          (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS months_since_registration,
          (((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (4)::double precision) + (cal.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) AS quarters_since_registration,
          visits.months_since_visit,
          visits.quarters_since_visit,
          bps.months_since_bp,
          bps.quarters_since_bp,
          bss.months_since_bs,
          bss.quarters_since_bs,
              CASE
                  WHEN ((bps.systolic IS NULL) OR (bps.diastolic IS NULL)) THEN 'unknown'::text
                  WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
                  ELSE 'uncontrolled'::text
              END AS last_bp_state,
              CASE
                  WHEN ((p.status)::text = 'dead'::text) THEN 'dead'::text
                  WHEN (((((cal.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)))) * (12)::double precision) + (cal.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at))))) < (12)::double precision) OR (visits.months_since_visit < (12)::double precision)) THEN 'under_care'::text
                  ELSE 'lost_to_follow_up'::text
              END AS htn_care_state,
              CASE
                  WHEN ((visits.months_since_visit >= (3)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bps.months_since_bp >= (3)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
                  WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
                  ELSE 'uncontrolled'::text
              END AS htn_treatment_outcome_in_last_3_months,
              CASE
                  WHEN ((visits.months_since_visit >= (2)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bps.months_since_bp >= (2)::double precision) OR (bps.months_since_bp IS NULL)) THEN 'visited_no_bp'::text
                  WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
                  ELSE 'uncontrolled'::text
              END AS htn_treatment_outcome_in_last_2_months,
              CASE
                  WHEN ((visits.quarters_since_visit >= (1)::double precision) OR (visits.quarters_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bps.quarters_since_bp >= (1)::double precision) OR (bps.quarters_since_bp IS NULL)) THEN 'visited_no_bp'::text
                  WHEN ((bps.systolic < 140) AND (bps.diastolic < 90)) THEN 'controlled'::text
                  ELSE 'uncontrolled'::text
              END AS htn_treatment_outcome_in_quarter,
              CASE
                  WHEN ((visits.months_since_visit >= (3)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bss.months_since_bs >= (3)::double precision) OR (bss.months_since_bs IS NULL)) THEN 'visited_no_bs'::text
                  ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_3_months,
              CASE
                  WHEN ((visits.months_since_visit >= (2)::double precision) OR (visits.months_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bss.months_since_bs >= (2)::double precision) OR (bss.months_since_bs IS NULL)) THEN 'visited_no_bs'::text
                  ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_2_months,
              CASE
                  WHEN ((visits.quarters_since_visit >= (1)::double precision) OR (visits.quarters_since_visit IS NULL)) THEN 'missed_visit'::text
                  WHEN ((bss.quarters_since_bs >= (1)::double precision) OR (bss.quarters_since_bs IS NULL)) THEN 'visited_no_bs'::text
                  ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_quarter,
          ((current_meds.amlodipine > past_meds.amlodipine) OR (current_meds.telmisartan > past_meds.telmisartan) OR (current_meds.losartan > past_meds.losartan) OR (current_meds.atenolol > past_meds.atenolol) OR (current_meds.enalapril > past_meds.enalapril) OR (current_meds.chlorthalidone > past_meds.chlorthalidone) OR (current_meds.hydrochlorothiazide > past_meds.hydrochlorothiazide)) AS titrated
        FROM (((((((((public.patients p
          LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.recorded_at)), 'YYYY-MM'::text) <= to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
          LEFT JOIN public.reporting_patient_blood_pressures bps ON (((p.id = bps.patient_id) AND (cal.month = bps.month) AND (cal.year = bps.year))))
          LEFT JOIN public.reporting_patient_blood_sugars bss ON (((p.id = bss.patient_id) AND (cal.month = bss.month) AND (cal.year = bss.year))))
          LEFT JOIN public.reporting_patient_visits visits ON (((p.id = visits.patient_id) AND (cal.month = visits.month) AND (cal.year = visits.year))))
          LEFT JOIN public.medical_histories mh ON (((p.id = mh.patient_id) AND (mh.deleted_at IS NULL))))
          LEFT JOIN public.reporting_prescriptions current_meds ON (((current_meds.patient_id = p.id) AND (cal.month_date = current_meds.month_date))))
          LEFT JOIN public.reporting_prescriptions past_meds ON (((past_meds.patient_id = p.id) AND (cal.month_date = (past_meds.month_date + '1 mon'::interval)))))
          JOIN public.reporting_facilities registration_facility ON ((registration_facility.facility_id = p.registration_facility_id)))
          JOIN public.reporting_facilities assigned_facility ON ((assigned_facility.facility_id = p.assigned_facility_id)))
        WHERE (p.deleted_at IS NULL)
        ORDER BY p.id, cal.month_date
        WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX index_reporting_patient_states_on_age ON public.reporting_patient_states USING btree (age);
      CREATE INDEX index_reporting_patient_states_on_gender ON public.reporting_patient_states USING btree (gender);
      CREATE INDEX index_reporting_patient_states_on_gender_and_age ON public.reporting_patient_states USING btree (gender, age);
      CREATE INDEX patient_states_assigned_block ON public.reporting_patient_states USING btree (assigned_block_region_id);
      CREATE INDEX patient_states_assigned_district ON public.reporting_patient_states USING btree (assigned_district_region_id);
      CREATE INDEX patient_states_assigned_facility ON public.reporting_patient_states USING btree (assigned_facility_region_id);
      CREATE INDEX patient_states_assigned_state ON public.reporting_patient_states USING btree (assigned_state_region_id);
      CREATE INDEX patient_states_care_state ON public.reporting_patient_states USING btree (hypertension, htn_care_state, htn_treatment_outcome_in_last_3_months);
      CREATE INDEX patient_states_month_date_assigned_facility ON public.reporting_patient_states USING btree (month_date, assigned_facility_id);
      CREATE INDEX patient_states_month_date_assigned_facility_region ON public.reporting_patient_states USING btree (month_date, assigned_facility_region_id);
      CREATE UNIQUE INDEX patient_states_month_date_patient_id ON public.reporting_patient_states USING btree (month_date, patient_id);
      CREATE INDEX patient_states_month_date_registration_facility ON public.reporting_patient_states USING btree (month_date, registration_facility_id);
      CREATE INDEX patient_states_month_date_registration_facility_region ON public.reporting_patient_states USING btree (month_date, registration_facility_region_id);
      CREATE INDEX reporting_patient_states_bp_facility_id ON public.reporting_patient_states USING btree (bp_facility_id);
      CREATE INDEX reporting_patient_states_titrated ON public.reporting_patient_states USING btree (titrated);
    SQL

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

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_overdue_patients AS
      WITH patients_with_appointments AS (
      SELECT DISTINCT ON (rps.patient_id, rps.month_date) rps.month_date,
        rps.patient_id,
        rps.hypertension,
        rps.diabetes,
        rps.htn_care_state,
        rps.month,
        rps.quarter,
        rps.year,
        rps.month_string,
        rps.quarter_string,
        rps.assigned_facility_id,
        rps.assigned_facility_slug,
        rps.assigned_facility_region_id,
        rps.assigned_block_slug,
        rps.assigned_block_region_id,
        rps.assigned_district_slug,
        rps.assigned_district_region_id,
        rps.assigned_state_slug,
        rps.assigned_state_region_id,
        rps.assigned_organization_slug,
        rps.assigned_organization_region_id,
        appointments.id AS previous_appointment_id,
        appointments.device_created_at AS previous_appointment_date,
        appointments.scheduled_date AS previous_appointment_schedule_date
        FROM (public.reporting_patient_states rps
          LEFT JOIN public.appointments ON (((appointments.patient_id = rps.patient_id) AND (appointments.device_created_at < rps.month_date))))
        WHERE (((rps.status)::text <> 'dead'::text) AND (rps.month_date > (now() - '2 years'::interval)))
        ORDER BY rps.patient_id, rps.month_date, appointments.device_created_at DESC
        ), patients_with_appointments_and_visits AS (
        SELECT patients_with_appointments.month_date,
          patients_with_appointments.patient_id,
          patients_with_appointments.hypertension,
          patients_with_appointments.diabetes,
          patients_with_appointments.htn_care_state,
          patients_with_appointments.month,
          patients_with_appointments.quarter,
          patients_with_appointments.year,
          patients_with_appointments.month_string,
          patients_with_appointments.quarter_string,
          patients_with_appointments.assigned_facility_id,
          patients_with_appointments.assigned_facility_slug,
          patients_with_appointments.assigned_facility_region_id,
          patients_with_appointments.assigned_block_slug,
          patients_with_appointments.assigned_block_region_id,
          patients_with_appointments.assigned_district_slug,
          patients_with_appointments.assigned_district_region_id,
          patients_with_appointments.assigned_state_slug,
          patients_with_appointments.assigned_state_region_id,
          patients_with_appointments.assigned_organization_slug,
          patients_with_appointments.assigned_organization_region_id,
          patients_with_appointments.previous_appointment_id,
          patients_with_appointments.previous_appointment_date,
          patients_with_appointments.previous_appointment_schedule_date,
          visits.visit_id,
          visits.visited_at_after_appointment
        FROM (patients_with_appointments
          LEFT JOIN LATERAL ( SELECT DISTINCT ON (blood_sugars.patient_id) blood_sugars.id AS visit_id,
                blood_sugars.patient_id,
                blood_sugars.recorded_at AS visited_at_after_appointment
                FROM public.blood_sugars
              WHERE ((blood_sugars.deleted_at IS NULL) AND (blood_sugars.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < blood_sugars.recorded_at) AND (blood_sugars.recorded_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT blood_pressures.id AS visit_id,
                blood_pressures.patient_id,
                blood_pressures.recorded_at AS visited_at_after_appointment
                FROM public.blood_pressures
              WHERE ((blood_pressures.deleted_at IS NULL) AND (blood_pressures.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < blood_pressures.recorded_at) AND (blood_pressures.recorded_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT patients_with_appointments_visit.id AS visit_id,
                patients_with_appointments_visit.patient_id,
                patients_with_appointments_visit.device_created_at AS visited_at_after_appointment
                FROM public.appointments patients_with_appointments_visit
              WHERE ((patients_with_appointments_visit.deleted_at IS NULL) AND (patients_with_appointments_visit.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < patients_with_appointments_visit.device_created_at) AND (patients_with_appointments_visit.device_created_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
            UNION ALL
              SELECT prescription_drugs.id AS visit_id,
                prescription_drugs.patient_id,
                prescription_drugs.device_created_at AS visited_at_after_appointment
                FROM public.prescription_drugs
              WHERE ((prescription_drugs.deleted_at IS NULL) AND (prescription_drugs.patient_id = patients_with_appointments.patient_id) AND (patients_with_appointments.previous_appointment_date < prescription_drugs.device_created_at) AND (prescription_drugs.device_created_at < ((patients_with_appointments.month_date + '1 mon'::interval) + '15 days'::interval)))
          ORDER BY 2, 3) visits ON ((patients_with_appointments.patient_id = visits.patient_id)))
        ), patient_with_call_results AS (
         SELECT DISTINCT ON (patients_with_appointments_and_visits.patient_id, patients_with_appointments_and_visits.month_date) patients_with_appointments_and_visits.month_date,
            patients_with_appointments_and_visits.patient_id,
            patients_with_appointments_and_visits.hypertension,
            patients_with_appointments_and_visits.diabetes,
            patients_with_appointments_and_visits.htn_care_state,
            patients_with_appointments_and_visits.month,
            patients_with_appointments_and_visits.quarter,
            patients_with_appointments_and_visits.year,
            patients_with_appointments_and_visits.month_string,
            patients_with_appointments_and_visits.quarter_string,
            patients_with_appointments_and_visits.assigned_facility_id,
            patients_with_appointments_and_visits.assigned_facility_slug,
            patients_with_appointments_and_visits.assigned_facility_region_id,
            patients_with_appointments_and_visits.assigned_block_slug,
            patients_with_appointments_and_visits.assigned_block_region_id,
            patients_with_appointments_and_visits.assigned_district_slug,
            patients_with_appointments_and_visits.assigned_district_region_id,
            patients_with_appointments_and_visits.assigned_state_slug,
            patients_with_appointments_and_visits.assigned_state_region_id,
            patients_with_appointments_and_visits.assigned_organization_slug,
            patients_with_appointments_and_visits.assigned_organization_region_id,
            patients_with_appointments_and_visits.previous_appointment_id,
            patients_with_appointments_and_visits.previous_appointment_date,
            patients_with_appointments_and_visits.previous_appointment_schedule_date,
            patients_with_appointments_and_visits.visit_id,
            patients_with_appointments_and_visits.visited_at_after_appointment,
            ((previous_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE 'UTC'::text) AS previous_called_at,
            previous_call_results.result_type AS previous_call_result_type,
            previous_call_results.remove_reason AS previous_call_removed_from_overdue_list_reason,
            ((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE 'UTC'::text) AS next_called_at,
            next_call_results.result_type AS next_call_result_type,
            next_call_results.remove_reason AS next_call_removed_from_overdue_list_reason,
            next_call_results.user_id AS called_by_user_id
           FROM ((patients_with_appointments_and_visits
             LEFT JOIN public.call_results previous_call_results ON (((patients_with_appointments_and_visits.patient_id = previous_call_results.patient_id) AND (((previous_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) < patients_with_appointments_and_visits.month_date) AND (previous_call_results.device_created_at > patients_with_appointments_and_visits.previous_appointment_schedule_date))))
             LEFT JOIN public.call_results next_call_results ON (((patients_with_appointments_and_visits.patient_id = next_call_results.patient_id) AND (((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) >= patients_with_appointments_and_visits.month_date) AND (((next_call_results.device_created_at AT TIME ZONE 'UTC'::text) AT TIME ZONE ( SELECT current_setting('TIMEZONE'::text) AS current_setting)) < (patients_with_appointments_and_visits.month_date + '1 mon'::interval)))))
          ORDER BY patients_with_appointments_and_visits.patient_id, patients_with_appointments_and_visits.month_date, next_call_results.device_created_at, previous_call_results.device_created_at DESC
        ), patient_with_call_results_and_phone AS (
         SELECT DISTINCT ON (patient_with_call_results.patient_id, patient_with_call_results.month_date) patient_with_call_results.month_date,
            patient_with_call_results.patient_id,
            patient_with_call_results.hypertension,
            patient_with_call_results.diabetes,
            patient_with_call_results.htn_care_state,
            patient_with_call_results.month,
            patient_with_call_results.quarter,
            patient_with_call_results.year,
            patient_with_call_results.month_string,
            patient_with_call_results.quarter_string,
            patient_with_call_results.assigned_facility_id,
            patient_with_call_results.assigned_facility_slug,
            patient_with_call_results.assigned_facility_region_id,
            patient_with_call_results.assigned_block_slug,
            patient_with_call_results.assigned_block_region_id,
            patient_with_call_results.assigned_district_slug,
            patient_with_call_results.assigned_district_region_id,
            patient_with_call_results.assigned_state_slug,
            patient_with_call_results.assigned_state_region_id,
            patient_with_call_results.assigned_organization_slug,
            patient_with_call_results.assigned_organization_region_id,
            patient_with_call_results.previous_appointment_id,
            patient_with_call_results.previous_appointment_date,
            patient_with_call_results.previous_appointment_schedule_date,
            patient_with_call_results.visit_id,
            patient_with_call_results.visited_at_after_appointment,
            patient_with_call_results.previous_called_at,
            patient_with_call_results.previous_call_result_type,
            patient_with_call_results.previous_call_removed_from_overdue_list_reason,
            patient_with_call_results.next_called_at,
            patient_with_call_results.next_call_result_type,
            patient_with_call_results.next_call_removed_from_overdue_list_reason,
            patient_with_call_results.called_by_user_id,
            patient_phone_numbers.number AS patient_phone_number
           FROM (patient_with_call_results
             LEFT JOIN public.patient_phone_numbers ON ((patient_phone_numbers.patient_id = patient_with_call_results.patient_id)))
          ORDER BY patient_with_call_results.patient_id, patient_with_call_results.month_date
        )
      SELECT patient_with_call_results_and_phone.month_date,
        patient_with_call_results_and_phone.patient_id,
        patient_with_call_results_and_phone.hypertension,
        patient_with_call_results_and_phone.diabetes,
        patient_with_call_results_and_phone.htn_care_state,
        patient_with_call_results_and_phone.month,
        patient_with_call_results_and_phone.quarter,
        patient_with_call_results_and_phone.year,
        patient_with_call_results_and_phone.month_string,
        patient_with_call_results_and_phone.quarter_string,
        patient_with_call_results_and_phone.assigned_facility_id,
        patient_with_call_results_and_phone.assigned_facility_slug,
        patient_with_call_results_and_phone.assigned_facility_region_id,
        patient_with_call_results_and_phone.assigned_block_slug,
        patient_with_call_results_and_phone.assigned_block_region_id,
        patient_with_call_results_and_phone.assigned_district_slug,
        patient_with_call_results_and_phone.assigned_district_region_id,
        patient_with_call_results_and_phone.assigned_state_slug,
        patient_with_call_results_and_phone.assigned_state_region_id,
        patient_with_call_results_and_phone.assigned_organization_slug,
        patient_with_call_results_and_phone.assigned_organization_region_id,
        patient_with_call_results_and_phone.previous_appointment_id,
        patient_with_call_results_and_phone.previous_appointment_date,
        patient_with_call_results_and_phone.previous_appointment_schedule_date,
        patient_with_call_results_and_phone.visited_at_after_appointment,
        patient_with_call_results_and_phone.called_by_user_id,
        patient_with_call_results_and_phone.next_called_at,
        patient_with_call_results_and_phone.previous_called_at,
        patient_with_call_results_and_phone.next_call_result_type,
        patient_with_call_results_and_phone.next_call_removed_from_overdue_list_reason,
        patient_with_call_results_and_phone.previous_call_result_type,
        patient_with_call_results_and_phone.previous_call_removed_from_overdue_list_reason,
            CASE
                WHEN (patient_with_call_results_and_phone.previous_appointment_id IS NULL) THEN 'no'::text
                WHEN (patient_with_call_results_and_phone.previous_appointment_schedule_date >= patient_with_call_results_and_phone.month_date) THEN 'no'::text
                WHEN ((patient_with_call_results_and_phone.previous_appointment_schedule_date < patient_with_call_results_and_phone.month_date) AND (patient_with_call_results_and_phone.visited_at_after_appointment < patient_with_call_results_and_phone.month_date)) THEN 'no'::text
                ELSE 'yes'::text
            END AS is_overdue,
            CASE
                WHEN (patient_with_call_results_and_phone.next_called_at IS NULL) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_called,
            CASE
                WHEN ((patient_with_call_results_and_phone.visited_at_after_appointment IS NULL) OR (patient_with_call_results_and_phone.next_called_at IS NULL)) THEN 'no'::text
                WHEN (patient_with_call_results_and_phone.visited_at_after_appointment > (patient_with_call_results_and_phone.next_called_at + '15 days'::interval)) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_visited_following_call,
            CASE
                WHEN (patient_with_call_results_and_phone.htn_care_state = 'lost_to_follow_up'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS ltfu,
            CASE
                WHEN (patient_with_call_results_and_phone.htn_care_state = 'under_care'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS under_care,
            CASE
                WHEN (patient_with_call_results_and_phone.patient_phone_number IS NULL) THEN 'no'::text
                ELSE 'yes'::text
            END AS has_phone,
            CASE
                WHEN ((patient_with_call_results_and_phone.previous_call_result_type)::text = 'removed_from_overdue_list'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS removed_from_overdue_list,
            CASE
                WHEN ((patient_with_call_results_and_phone.next_call_result_type)::text = 'removed_from_overdue_list'::text) THEN 'yes'::text
                ELSE 'no'::text
            END AS removed_from_overdue_list_during_the_month
      FROM patient_with_call_results_and_phone
      WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX overdue_patients_assigned_facility_region_id ON public.reporting_overdue_patients USING btree (assigned_facility_region_id);
      CREATE UNIQUE INDEX overdue_patients_month_date_patient_id ON public.reporting_overdue_patients USING btree (month_date, patient_id);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_states AS
      WITH registered_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_registrations
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), registered_diabetes_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_diabetes_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_diabetes_registrations
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.diabetes = 'yes'::text)
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), registered_hypertension_and_diabetes_patients AS (
         SELECT reporting_patient_states.registration_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(*) AS cumulative_hypertension_and_diabetes_registrations,
            count(*) FILTER (WHERE (reporting_patient_states.months_since_registration = (0)::double precision)) AS monthly_hypertension_and_diabetes_registrations
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.diabetes = 'yes'::text))
          GROUP BY reporting_patient_states.registration_facility_region_id, reporting_patient_states.month_date
        ), assigned_patients AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS dead,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state <> 'dead'::text)) AS cumulative_assigned_patients
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.hypertension = 'yes'::text)
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), assigned_diabetes_patients AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS diabetes_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS diabetes_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'dead'::text)) AS diabetes_dead,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state <> 'dead'::text)) AS cumulative_assigned_diabetic_patients
           FROM public.reporting_patient_states
          WHERE (reporting_patient_states.diabetes = 'yes'::text)
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), adjusted_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'controlled'::text))) AS controlled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'uncontrolled'::text))) AS uncontrolled_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS missed_visit_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.htn_treatment_outcome_in_last_3_months = 'visited_no_bp'::text))) AS visited_no_bp_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS patients_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS patients_lost_to_follow_up
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), adjusted_diabetes_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_below_200'::text))) AS bs_below_200_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300'::text))) AS bs_200_to_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'random'::text))) AS random_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'post_prandial'::text))) AS post_prandial_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'fasting'::text))) AS fasting_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text) AND ((reporting_patient_states.blood_sugar_type)::text = 'hba1c'::text))) AS hba1c_bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'bs_over_300'::text))) AS bs_over_300_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS bs_missed_visit_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'under_care'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'visited_no_bs'::text))) AS visited_no_bs_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE ((reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text) AND (reporting_patient_states.diabetes_treatment_outcome_in_last_3_months = 'missed_visit'::text))) AS bs_missed_visit_lost_to_follow_up,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'under_care'::text)) AS diabetes_patients_under_care,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_care_state = 'lost_to_follow_up'::text)) AS diabetes_patients_lost_to_follow_up
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.diabetes = 'yes'::text) AND (reporting_patient_states.months_since_registration >= (3)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.month_date,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_last_2_months = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND (reporting_patient_states.months_since_registration = (2)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.month_date
        ), monthly_overdue_calls AS (
         SELECT reporting_overdue_calls.appointment_facility_region_id AS region_id,
            reporting_overdue_calls.month_date,
            count(DISTINCT reporting_overdue_calls.appointment_id) AS call_results
           FROM public.reporting_overdue_calls
          GROUP BY reporting_overdue_calls.appointment_facility_region_id, reporting_overdue_calls.month_date
        ), monthly_follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS follow_ups
           FROM public.reporting_patient_follow_ups
          WHERE (reporting_patient_follow_ups.hypertension = 'yes'::text)
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        ), monthly_diabetes_follow_ups AS (
         SELECT reporting_patient_follow_ups.facility_id,
            reporting_patient_follow_ups.month_date,
            count(DISTINCT reporting_patient_follow_ups.patient_id) AS follow_ups
           FROM public.reporting_patient_follow_ups
          WHERE (reporting_patient_follow_ups.diabetes = 'yes'::text)
          GROUP BY reporting_patient_follow_ups.facility_id, reporting_patient_follow_ups.month_date
        ), monthly_hypertension_overdue_patients AS (
         SELECT reporting_overdue_patients.assigned_facility_region_id,
            reporting_overdue_patients.month_date,
            count(*) FILTER (WHERE (reporting_overdue_patients.is_overdue = 'yes'::text)) AS overdue_patients,
            count(*) FILTER (WHERE ((reporting_overdue_patients.is_overdue = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_overdue_patients,
            count(*) FILTER (WHERE (reporting_overdue_patients.has_called = 'yes'::text)) AS patients_called,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS patients_called_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS patients_called_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS patients_called_with_result_removed_from_list,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_patients_called,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS contactable_patients_called_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS contactable_patients_called_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_called = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS contactable_patients_called_with_result_removed_from_list,
            count(*) FILTER (WHERE (reporting_overdue_patients.has_visited_following_call = 'yes'::text)) AS patients_returned_after_call,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS patients_returned_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS patients_returned_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS patients_returned_with_result_removed_from_list,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text))) AS contactable_patients_returned_after_call,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'agreed_to_visit'::text))) AS contactable_patients_returned_with_result_agreed_to_visit,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'remind_to_call_later'::text))) AS contactable_patients_returned_with_result_remind_to_call_later,
            count(*) FILTER (WHERE ((reporting_overdue_patients.has_visited_following_call = 'yes'::text) AND (reporting_overdue_patients.removed_from_overdue_list = 'no'::text) AND (reporting_overdue_patients.has_phone = 'yes'::text) AND ((reporting_overdue_patients.next_call_result_type)::text = 'removed_from_overdue_list'::text))) AS contactable_patients_returned_with_result_removed_from_list
           FROM public.reporting_overdue_patients
          WHERE ((reporting_overdue_patients.hypertension = 'yes'::text) AND (reporting_overdue_patients.under_care = 'yes'::text))
          GROUP BY reporting_overdue_patients.assigned_facility_region_id, reporting_overdue_patients.month_date
        )
      SELECT cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string,
          rf.facility_id,
          rf.facility_name,
          rf.facility_type,
          rf.facility_size,
          rf.facility_region_id,
          rf.facility_region_name,
          rf.facility_region_slug,
          rf.block_region_id,
          rf.block_name,
          rf.block_slug,
          rf.district_id,
          rf.district_region_id,
          rf.district_name,
          rf.district_slug,
          rf.state_region_id,
          rf.state_name,
          rf.state_slug,
          rf.organization_id,
          rf.organization_region_id,
          rf.organization_name,
          rf.organization_slug,
          registered_patients.cumulative_registrations,
          registered_patients.monthly_registrations,
          registered_diabetes_patients.cumulative_diabetes_registrations,
          registered_diabetes_patients.monthly_diabetes_registrations,
          registered_hypertension_and_diabetes_patients.cumulative_hypertension_and_diabetes_registrations,
          registered_hypertension_and_diabetes_patients.monthly_hypertension_and_diabetes_registrations,
          assigned_patients.under_care,
          assigned_patients.lost_to_follow_up,
          assigned_patients.dead,
          assigned_patients.cumulative_assigned_patients,
          assigned_diabetes_patients.diabetes_under_care,
          assigned_diabetes_patients.diabetes_lost_to_follow_up,
          assigned_diabetes_patients.diabetes_dead,
          assigned_diabetes_patients.cumulative_assigned_diabetic_patients,
          adjusted_outcomes.controlled_under_care AS adjusted_controlled_under_care,
          adjusted_outcomes.uncontrolled_under_care AS adjusted_uncontrolled_under_care,
          adjusted_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
          adjusted_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,
          adjusted_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
          adjusted_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,
          adjusted_outcomes.patients_under_care AS adjusted_patients_under_care,
          adjusted_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,
          adjusted_diabetes_outcomes.random_bs_below_200_under_care AS adjusted_random_bs_below_200_under_care,
          adjusted_diabetes_outcomes.fasting_bs_below_200_under_care AS adjusted_fasting_bs_below_200_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_below_200_under_care AS adjusted_post_prandial_bs_below_200_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_below_200_under_care AS adjusted_hba1c_bs_below_200_under_care,
          adjusted_diabetes_outcomes.bs_below_200_under_care AS adjusted_bs_below_200_under_care,
          adjusted_diabetes_outcomes.random_bs_200_to_300_under_care AS adjusted_random_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.fasting_bs_200_to_300_under_care AS adjusted_fasting_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_200_to_300_under_care AS adjusted_post_prandial_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_200_to_300_under_care AS adjusted_hba1c_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.bs_200_to_300_under_care AS adjusted_bs_200_to_300_under_care,
          adjusted_diabetes_outcomes.random_bs_over_300_under_care AS adjusted_random_bs_over_300_under_care,
          adjusted_diabetes_outcomes.fasting_bs_over_300_under_care AS adjusted_fasting_bs_over_300_under_care,
          adjusted_diabetes_outcomes.post_prandial_bs_over_300_under_care AS adjusted_post_prandial_bs_over_300_under_care,
          adjusted_diabetes_outcomes.hba1c_bs_over_300_under_care AS adjusted_hba1c_bs_over_300_under_care,
          adjusted_diabetes_outcomes.bs_over_300_under_care AS adjusted_bs_over_300_under_care,
          adjusted_diabetes_outcomes.bs_missed_visit_under_care AS adjusted_bs_missed_visit_under_care,
          adjusted_diabetes_outcomes.visited_no_bs_under_care AS adjusted_visited_no_bs_under_care,
          adjusted_diabetes_outcomes.bs_missed_visit_lost_to_follow_up AS adjusted_bs_missed_visit_lost_to_follow_up,
          adjusted_diabetes_outcomes.diabetes_patients_under_care AS adjusted_diabetes_patients_under_care,
          adjusted_diabetes_outcomes.diabetes_patients_lost_to_follow_up AS adjusted_diabetes_patients_lost_to_follow_up,
          monthly_cohort_outcomes.controlled AS monthly_cohort_controlled,
          monthly_cohort_outcomes.uncontrolled AS monthly_cohort_uncontrolled,
          monthly_cohort_outcomes.missed_visit AS monthly_cohort_missed_visit,
          monthly_cohort_outcomes.visited_no_bp AS monthly_cohort_visited_no_bp,
          monthly_cohort_outcomes.patients AS monthly_cohort_patients,
          monthly_overdue_calls.call_results AS monthly_overdue_calls,
          monthly_follow_ups.follow_ups AS monthly_follow_ups,
          monthly_diabetes_follow_ups.follow_ups AS monthly_diabetes_follow_ups,
          reporting_facility_appointment_scheduled_days.htn_total_appts_scheduled AS total_appts_scheduled,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_0_to_14_days AS appts_scheduled_0_to_14_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_15_to_31_days AS appts_scheduled_15_to_31_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_32_to_62_days AS appts_scheduled_32_to_62_days,
          reporting_facility_appointment_scheduled_days.htn_appts_scheduled_more_than_62_days AS appts_scheduled_more_than_62_days,
          reporting_facility_appointment_scheduled_days.diabetes_total_appts_scheduled,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_0_to_14_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_15_to_31_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_32_to_62_days,
          reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_more_than_62_days,
          monthly_hypertension_overdue_patients.overdue_patients,
          monthly_hypertension_overdue_patients.contactable_overdue_patients,
          monthly_hypertension_overdue_patients.patients_called,
          monthly_hypertension_overdue_patients.contactable_patients_called,
          monthly_hypertension_overdue_patients.patients_called_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.patients_called_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.patients_called_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.contactable_patients_called_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.patients_returned_after_call,
          monthly_hypertension_overdue_patients.contactable_patients_returned_after_call,
          monthly_hypertension_overdue_patients.patients_returned_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.patients_returned_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.patients_returned_with_result_removed_from_list,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_agreed_to_visit,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_remind_to_call_later,
          monthly_hypertension_overdue_patients.contactable_patients_returned_with_result_removed_from_list
        FROM ((((((((((((((public.reporting_facilities rf
          JOIN public.reporting_months cal ON (true))
          LEFT JOIN registered_patients ON (((registered_patients.month_date = cal.month_date) AND (registered_patients.region_id = rf.facility_region_id))))
          LEFT JOIN registered_diabetes_patients ON (((registered_diabetes_patients.month_date = cal.month_date) AND (registered_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN registered_hypertension_and_diabetes_patients ON (((registered_hypertension_and_diabetes_patients.month_date = cal.month_date) AND (registered_hypertension_and_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN assigned_patients ON (((assigned_patients.month_date = cal.month_date) AND (assigned_patients.region_id = rf.facility_region_id))))
          LEFT JOIN assigned_diabetes_patients ON (((assigned_diabetes_patients.month_date = cal.month_date) AND (assigned_diabetes_patients.region_id = rf.facility_region_id))))
          LEFT JOIN adjusted_outcomes ON (((adjusted_outcomes.month_date = cal.month_date) AND (adjusted_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN adjusted_diabetes_outcomes ON (((adjusted_diabetes_outcomes.month_date = cal.month_date) AND (adjusted_diabetes_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_cohort_outcomes ON (((monthly_cohort_outcomes.month_date = cal.month_date) AND (monthly_cohort_outcomes.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_overdue_calls ON (((monthly_overdue_calls.month_date = cal.month_date) AND (monthly_overdue_calls.region_id = rf.facility_region_id))))
          LEFT JOIN monthly_follow_ups ON (((monthly_follow_ups.month_date = cal.month_date) AND (monthly_follow_ups.facility_id = rf.facility_id))))
          LEFT JOIN monthly_diabetes_follow_ups ON (((monthly_diabetes_follow_ups.month_date = cal.month_date) AND (monthly_diabetes_follow_ups.facility_id = rf.facility_id))))
          LEFT JOIN public.reporting_facility_appointment_scheduled_days ON (((reporting_facility_appointment_scheduled_days.month_date = cal.month_date) AND (reporting_facility_appointment_scheduled_days.facility_id = rf.facility_id))))
          LEFT JOIN monthly_hypertension_overdue_patients ON (((monthly_hypertension_overdue_patients.month_date = cal.month_date) AND (monthly_hypertension_overdue_patients.assigned_facility_region_id = rf.facility_region_id))))
        WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX index_fs_block_month_date ON public.reporting_facility_states USING btree (block_region_id, month_date);
      CREATE INDEX index_fs_district_month_date ON public.reporting_facility_states USING btree (district_region_id, month_date);
      CREATE UNIQUE INDEX index_fs_month_date_region_id ON public.reporting_facility_states USING btree (month_date, facility_region_id);
      CREATE INDEX index_fs_organization_month_date ON public.reporting_facility_states USING btree (organization_region_id, month_date);
      CREATE INDEX index_fs_state_month_date ON public.reporting_facility_states USING btree (state_region_id, month_date);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_quarterly_facility_states AS
      WITH quarterly_cohort_outcomes AS (
         SELECT reporting_patient_states.assigned_facility_region_id AS region_id,
            reporting_patient_states.quarter_string,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'visited_no_bp'::text)) AS visited_no_bp,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'controlled'::text)) AS controlled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'uncontrolled'::text)) AS uncontrolled,
            count(DISTINCT reporting_patient_states.patient_id) FILTER (WHERE (reporting_patient_states.htn_treatment_outcome_in_quarter = 'missed_visit'::text)) AS missed_visit,
            count(DISTINCT reporting_patient_states.patient_id) AS patients
           FROM public.reporting_patient_states
          WHERE ((reporting_patient_states.hypertension = 'yes'::text) AND ((((reporting_patient_states.month)::integer % 3) = 0) OR (reporting_patient_states.month_string = to_char(now(), 'YYYY-MM'::text))) AND (reporting_patient_states.quarters_since_registration = (1)::double precision))
          GROUP BY reporting_patient_states.assigned_facility_region_id, reporting_patient_states.quarter_string
        )
      SELECT cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string,
          rf.facility_id,
          rf.facility_name,
          rf.facility_type,
          rf.facility_size,
          rf.facility_region_id,
          rf.facility_region_name,
          rf.facility_region_slug,
          rf.block_region_id,
          rf.block_name,
          rf.block_slug,
          rf.district_id,
          rf.district_region_id,
          rf.district_name,
          rf.district_slug,
          rf.state_region_id,
          rf.state_name,
          rf.state_slug,
          rf.organization_id,
          rf.organization_region_id,
          rf.organization_name,
          rf.organization_slug,
          quarterly_cohort_outcomes.controlled AS quarterly_cohort_controlled,
          quarterly_cohort_outcomes.uncontrolled AS quarterly_cohort_uncontrolled,
          quarterly_cohort_outcomes.missed_visit AS quarterly_cohort_missed_visit,
          quarterly_cohort_outcomes.visited_no_bp AS quarterly_cohort_visited_no_bp,
          quarterly_cohort_outcomes.patients AS quarterly_cohort_patients
        FROM ((public.reporting_facilities rf
          JOIN public.reporting_months cal ON (((((cal.month)::integer % 3) = 0) OR (cal.month_string = to_char(now(), 'YYYY-MM'::text)))))
          LEFT JOIN quarterly_cohort_outcomes ON (((quarterly_cohort_outcomes.quarter_string = cal.quarter_string) AND (quarterly_cohort_outcomes.region_id = rf.facility_region_id))))
        WITH NO DATA;
    SQL

    execute <<~SQL
      CREATE INDEX index_qfs_facility_id ON public.reporting_quarterly_facility_states USING btree (facility_id);
      CREATE UNIQUE INDEX index_qfs_quarter_string_region_id ON public.reporting_quarterly_facility_states USING btree (quarter_string, facility_region_id);
    SQL
  end
end
