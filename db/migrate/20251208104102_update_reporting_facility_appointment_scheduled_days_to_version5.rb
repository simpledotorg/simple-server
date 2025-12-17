class UpdateReportingFacilityAppointmentScheduledDaysToVersion5 < ActiveRecord::Migration[6.1]
  def up
    drop_view :reporting_facility_states, materialized: true
    drop_view :reporting_facility_appointment_scheduled_days, materialized: true

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_appointment_scheduled_days AS
        WITH latest_medical_histories AS (
          SELECT DISTINCT ON (patient_id) mh.*
          FROM medical_histories mh
          WHERE  mh.deleted_at IS NULL
          ORDER BY patient_id, mh.device_created_at DESC
        ),
        latest_appointments_per_patient_per_month AS (
          SELECT DISTINCT ON (patient_id, month_date) a.*,
            lmh.hypertension,
            lmh.diabetes,
            to_char(a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date
          FROM appointments a
          INNER JOIN patients p ON p.id = a.patient_id
          INNER JOIN latest_medical_histories lmh ON lmh.patient_id = a.patient_id
          WHERE a.scheduled_date >= date_trunc('day', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
            AND a.device_created_at >= date_trunc('month', (now() AT TIME ZONE 'UTC') - INTERVAL '6 months')
            AND date_trunc('month', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
                > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
            AND p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL
            AND a.deleted_at IS NULL
            AND (lmh.hypertension = 'yes'  OR lmh.diabetes = 'yes')
          ORDER BY a.patient_id, month_date, a.device_created_at desc
        ),
        scheduled_days_distribution AS (
          SELECT month_date,
            width_bucket(
              extract('days' FROM (scheduled_date - date_trunc('day', device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))))::integer,
              array[0, 15, 32, 63]
            ) bucket,
            COUNT(*) number_of_appointments,
            hypertension,
            diabetes,
            creation_facility_id facility_id
          FROM latest_appointments_per_patient_per_month
          GROUP BY bucket, creation_facility_id, month_date, hypertension, diabetes
        )
        SELECT facility_id,
          month_date,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_0_to_14_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_15_to_31_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_32_to_62_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_more_than_62_days,
          (SUM(number_of_appointments) FILTER (WHERE hypertension = 'yes'))::integer htn_total_appts_scheduled,

          (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_0_to_14_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_15_to_31_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_32_to_62_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_more_than_62_days,
          (SUM(number_of_appointments) FILTER (WHERE diabetes = 'yes'))::integer diabetes_total_appts_scheduled
        FROM scheduled_days_distribution
        GROUP BY facility_id, month_date
      WITH NO DATA;

    SQL

    add_index :reporting_facility_appointment_scheduled_days, [:month_date, :facility_id], name: "index_reporting_facility_appointment_scheduled_days", unique: true

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

    add_index "reporting_facility_states", ["block_region_id", "month_date"], name: "index_fs_block_month_date"
    add_index "reporting_facility_states", ["district_region_id", "month_date"], name: "index_fs_district_month_date"
    add_index "reporting_facility_states", ["month_date", "facility_region_id"], name: "index_fs_month_date_region_id", unique: true
    add_index "reporting_facility_states", ["organization_region_id", "month_date"], name: "index_fs_organization_month_date"
    add_index "reporting_facility_states", ["state_region_id", "month_date"], name: "index_fs_state_month_date"
  end

  def down
    drop_view :reporting_facility_states, materialized: true
    drop_view :reporting_facility_appointment_scheduled_days, materialized: true

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_facility_appointment_scheduled_days AS
        WITH latest_medical_histories AS (
          SELECT DISTINCT ON (patient_id) mh.*
          FROM medical_histories mh
          WHERE  mh.deleted_at IS NULL
          ORDER BY patient_id, mh.device_created_at DESC
        ),
        latest_appointments_per_patient_per_month AS (
          SELECT DISTINCT ON (patient_id, month_date) a.*,
            lmh.hypertension,
            lmh.diabetes,
            to_char(a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date
          FROM appointments a
          INNER JOIN patients p ON p.id = a.patient_id
          INNER JOIN latest_medical_histories lmh ON lmh.patient_id = a.patient_id
          WHERE a.scheduled_date >= date_trunc('day', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
            AND a.device_created_at >= date_trunc('month', (now() AT TIME ZONE 'UTC') - INTERVAL '6 months')
            AND date_trunc('month', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
                > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
            AND p.deleted_at IS NULL and a.deleted_at IS NULL
            AND (lmh.hypertension = 'yes'  OR lmh.diabetes = 'yes')
          ORDER BY a.patient_id, month_date, a.device_created_at desc
        ),
        scheduled_days_distribution AS (
          SELECT month_date,
            width_bucket(
              extract('days' FROM (scheduled_date - date_trunc('day', device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))))::integer,
              array[0, 15, 32, 63]
            ) bucket,
            COUNT(*) number_of_appointments,
            hypertension,
            diabetes,
            creation_facility_id facility_id
          FROM latest_appointments_per_patient_per_month
          GROUP BY bucket, creation_facility_id, month_date, hypertension, diabetes
        )
        SELECT facility_id,
          month_date,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_0_to_14_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_15_to_31_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_32_to_62_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_more_than_62_days,
          (SUM(number_of_appointments) FILTER (WHERE hypertension = 'yes'))::integer htn_total_appts_scheduled,

          (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_0_to_14_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_15_to_31_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_32_to_62_days,
          (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_more_than_62_days,
          (SUM(number_of_appointments) FILTER (WHERE diabetes = 'yes'))::integer diabetes_total_appts_scheduled
        FROM scheduled_days_distribution
        GROUP BY facility_id, month_date
      WITH NO DATA;

    SQL

    add_index :reporting_facility_appointment_scheduled_days, [:month_date, :facility_id], name: "index_reporting_facility_appointment_scheduled_days", unique: true

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

    add_index "reporting_facility_states", ["block_region_id", "month_date"], name: "index_fs_block_month_date"
    add_index "reporting_facility_states", ["district_region_id", "month_date"], name: "index_fs_district_month_date"
    add_index "reporting_facility_states", ["month_date", "facility_region_id"], name: "index_fs_month_date_region_id", unique: true
    add_index "reporting_facility_states", ["organization_region_id", "month_date"], name: "index_fs_organization_month_date"
    add_index "reporting_facility_states", ["state_region_id", "month_date"], name: "index_fs_state_month_date"
  end
end
