WITH
    registered_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_registrations

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    registered_diabetes_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_diabetes_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_diabetes_registrations

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
        GROUP BY 1, 2
    ),

    registered_hypertension_and_diabetes_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_hypertension_and_diabetes_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_hypertension_and_diabetes_registrations

        FROM reporting_patient_states
        WHERE (hypertension = 'yes' and diabetes = 'yes')
        GROUP BY 1, 2
    ),

    assigned_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS dead,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state != 'dead') AS cumulative_assigned_patients

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    assigned_diabetes_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS diabetes_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS diabetes_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS diabetes_dead,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state != 'dead') AS cumulative_assigned_diabetic_patients

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
        GROUP BY 1, 2
    ),

    adjusted_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'controlled') AS controlled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'uncontrolled') AS uncontrolled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    ),

    adjusted_diabetes_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200' AND blood_sugar_type = 'random') AS random_bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200' AND blood_sugar_type = 'post_prandial') AS post_prandial_bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200' AND blood_sugar_type = 'fasting') AS fasting_bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200' AND blood_sugar_type = 'hba1c') AS hba1c_bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_below_200') AS bs_below_200_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300' AND blood_sugar_type = 'random') AS random_bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300' AND blood_sugar_type = 'post_prandial') AS post_prandial_bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300' AND blood_sugar_type = 'fasting') AS fasting_bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300' AND blood_sugar_type = 'hba1c') AS hba1c_bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_200_to_300') AS bs_200_to_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300' AND blood_sugar_type = 'random') AS random_bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300' AND blood_sugar_type = 'post_prandial') AS post_prandial_bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300' AND blood_sugar_type = 'fasting') AS fasting_bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300' AND blood_sugar_type = 'hba1c') AS hba1c_bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'bs_over_300') AS bs_over_300_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'missed_visit') AS bs_missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND diabetes_treatment_outcome_in_last_3_months = 'visited_no_bs') AS visited_no_bs_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND diabetes_treatment_outcome_in_last_3_months = 'missed_visit') AS bs_missed_visit_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS diabetes_patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS diabetes_patients_lost_to_follow_up

        FROM reporting_patient_states
        WHERE diabetes = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    ),

    monthly_cohort_outcomes AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'controlled') AS controlled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'uncontrolled') AS uncontrolled,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'missed_visit') AS missed_visit,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_2_months = 'visited_no_bp') AS visited_no_bp,
               COUNT(distinct(patient_id)) AS patients

        FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration = 2
        GROUP BY 1, 2
    ),

    monthly_overdue_calls AS (
        SELECT appointment_facility_region_id AS region_id, month_date,
               COUNT(distinct(appointment_id)) AS call_results
        FROM reporting_overdue_calls
        GROUP BY 1, 2
    ),

    monthly_follow_ups AS (
        SELECT facility_id, month_date, COUNT(distinct(patient_id)) as follow_ups
        FROM reporting_patient_follow_ups
        WHERE hypertension = 'yes'
        GROUP BY facility_id, month_date
    ),

    monthly_diabetes_follow_ups AS (
        SELECT facility_id, month_date, COUNT(distinct(patient_id)) as follow_ups
        FROM reporting_patient_follow_ups
        WHERE diabetes = 'yes'
        GROUP BY facility_id, month_date
    ),

    monthly_overdue_patients as (
        SELECT assigned_facility_region_id as region_id, month_date,
           COUNT(*) filter(where ltfu = 'no' and is_overdue = 'yes')  as overdue,
           COUNT(*) filter(where ltfu = 'no' and is_overdue = 'yes' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_overdue,

           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no') as called,
           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_called,


           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and next_call_result_type = 'agreed_to_visit') as called_with_result_agreed_to_visit,
           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and removed_from_overdue_list = 'no' and has_phone = 'yes' and next_call_result_type = 'agreed_to_visit') as filtered_called_with_result_agreed_to_visit,


           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and next_call_result_type = 'remind_to_call_later') as called_with_result_remind_to_call_later,
           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and removed_from_overdue_list = 'no' and has_phone = 'yes' and next_call_result_type = 'remind_to_call_later') as filtered_called_with_result_remind_to_call_later,

           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and next_call_result_type = 'removed_from_overdue_list') as called_with_result_remove_from_overdue_list,
           COUNT(*) filter(where has_called = 'yes' and ltfu = 'no' and removed_from_overdue_list = 'no' and has_phone = 'yes' and next_call_result_type = 'removed_from_overdue_list') as filtered_called_with_result_remove_from_overdue_list,
           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no') as returned_after_call,
           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_returned_after_call,

           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'agreed_to_visit') as returned_after_call_with_result_agreed_to_visit,
           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'agreed_to_visit' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_returned_after_call_with_result_agreed_to_visit,

           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'remind_to_call_later') as returned_after_call_with_result_remind_to_call_later,
           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'remind_to_call_later' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_returned_after_call_with_result_remind_to_call_later,

           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'removed_from_overdue_list') as returned_after_call_with_result_remove_from_overdue_list,
           COUNT(*) filter(where has_visited_following_call = 'yes' and ltfu = 'no' and next_call_result_type = 'removed_from_overdue_list' and removed_from_overdue_list = 'no' and has_phone = 'yes') as filtered_returned_after_call_with_result_remove_from_overdue_list

    FROM reporting_overdue_patients
    WHERE hypertension = 'yes'
    GROUP BY assigned_facility_region_id, month_date
    )

SELECT
-- months and facilities
cal.*,
rf.*,

-- registration counts of hypertensive patients
registered_patients.cumulative_registrations,
registered_patients.monthly_registrations,

-- registration counts of diabetic patients
registered_diabetes_patients.cumulative_diabetes_registrations,
registered_diabetes_patients.monthly_diabetes_registrations,

-- registration counts of hypertension and diabetes patients
registered_hypertension_and_diabetes_patients.cumulative_hypertension_and_diabetes_registrations,
registered_hypertension_and_diabetes_patients.monthly_hypertension_and_diabetes_registrations,

-- htn assigned counts by care state
assigned_patients.under_care,
assigned_patients.lost_to_follow_up,
assigned_patients.dead,
assigned_patients.cumulative_assigned_patients,

-- diabetes assigned counts by care state
assigned_diabetes_patients.diabetes_under_care,
assigned_diabetes_patients.diabetes_lost_to_follow_up,
assigned_diabetes_patients.diabetes_dead,
assigned_diabetes_patients.cumulative_assigned_diabetic_patients,

-- adjusted htn outcomes
adjusted_outcomes.controlled_under_care AS adjusted_controlled_under_care,
adjusted_outcomes.uncontrolled_under_care AS adjusted_uncontrolled_under_care,
adjusted_outcomes.missed_visit_under_care AS adjusted_missed_visit_under_care,
adjusted_outcomes.visited_no_bp_under_care AS adjusted_visited_no_bp_under_care,

adjusted_outcomes.missed_visit_lost_to_follow_up AS adjusted_missed_visit_lost_to_follow_up,
adjusted_outcomes.visited_no_bp_lost_to_follow_up AS adjusted_visited_no_bp_lost_to_follow_up,

adjusted_outcomes.patients_under_care AS adjusted_patients_under_care,
adjusted_outcomes.patients_lost_to_follow_up AS adjusted_patients_lost_to_follow_up,

-- adjusted ¸ outcomes
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

-- monthly cohort outcomes
monthly_cohort_outcomes.controlled AS monthly_cohort_controlled,
monthly_cohort_outcomes.uncontrolled AS monthly_cohort_uncontrolled,
monthly_cohort_outcomes.missed_visit AS monthly_cohort_missed_visit,
monthly_cohort_outcomes.visited_no_bp AS monthly_cohort_visited_no_bp,
monthly_cohort_outcomes.patients AS monthly_cohort_patients,

-- monthly overdue calls
monthly_overdue_calls.call_results AS monthly_overdue_calls,

-- monthly htn follow ups
monthly_follow_ups.follow_ups AS monthly_follow_ups,

-- monthly diabetes follow ups
monthly_diabetes_follow_ups.follow_ups AS monthly_diabetes_follow_ups,

-- appointment scheduled days distribution
reporting_facility_appointment_scheduled_days.htn_total_appts_scheduled AS total_appts_scheduled,
reporting_facility_appointment_scheduled_days.htn_appts_scheduled_0_to_14_days AS appts_scheduled_0_to_14_days,
reporting_facility_appointment_scheduled_days.htn_appts_scheduled_15_to_31_days AS appts_scheduled_15_to_31_days,
reporting_facility_appointment_scheduled_days.htn_appts_scheduled_32_to_62_days AS appts_scheduled_32_to_62_days,
reporting_facility_appointment_scheduled_days.htn_appts_scheduled_more_than_62_days AS appts_scheduled_more_than_62_days,

reporting_facility_appointment_scheduled_days.diabetes_total_appts_scheduled AS diabetes_total_appts_scheduled,
reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_0_to_14_days AS diabetes_appts_scheduled_0_to_14_days,
reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_15_to_31_days AS diabetes_appts_scheduled_15_to_31_days,
reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_32_to_62_days AS diabetes_appts_scheduled_32_to_62_days,
reporting_facility_appointment_scheduled_days.diabetes_appts_scheduled_more_than_62_days AS diabetes_appts_scheduled_more_than_62_days,

-- monthly overdue patients
monthly_overdue_patients.overdue,
monthly_overdue_patients.overdue * 100.0 / nullif(assigned_patients.under_care, 0) as percentage_overdue,

monthly_overdue_patients.filtered_overdue,
monthly_overdue_patients.filtered_overdue * 100.0 / nullif(assigned_patients.under_care, 0) as filtered_percentage_overdue,

-- monthly overdue calls made to overdue patients
monthly_overdue_patients.called,
monthly_overdue_patients.called * 100.0 / nullif(overdue, 0) as percentage_called,

monthly_overdue_patients.filtered_called,
monthly_overdue_patients.filtered_called * 100.0 / nullif(filtered_overdue, 0) as filtered_percentage_called,

-- monthly overdue calls grouped by call result
monthly_overdue_patients.called_with_result_agreed_to_visit,
monthly_overdue_patients.called_with_result_agreed_to_visit * 100.0 / nullif(called, 0) as percentage_called_with_result_agreed_to_visit,

monthly_overdue_patients.called_with_result_remind_to_call_later,
monthly_overdue_patients.called_with_result_remind_to_call_later * 100.0 / nullif(called, 0) as percentage_called_with_result_remind_to_call_later,

monthly_overdue_patients.called_with_result_remove_from_overdue_list,
monthly_overdue_patients.called_with_result_remove_from_overdue_list * 100.0 / nullif(called, 0) as percentage_called_with_result_remove_from_overdue_list,

monthly_overdue_patients.filtered_called_with_result_agreed_to_visit,
monthly_overdue_patients.filtered_called_with_result_agreed_to_visit * 100.0 / nullif(filtered_called, 0) as filtered_percentage_called_with_result_agreed_to_visit,

monthly_overdue_patients.filtered_called_with_result_remind_to_call_later,
monthly_overdue_patients.filtered_called_with_result_remind_to_call_later * 100.0 / nullif(filtered_called, 0) as filtered_percentage_called_with_result_remind_to_call_later,

monthly_overdue_patients.filtered_called_with_result_remove_from_overdue_list,
monthly_overdue_patients.filtered_called_with_result_remove_from_overdue_list * 100.0 / nullif(filtered_called, 0) as filtered_percentage_called_with_result_remove_from_overdue_list,

-- monthly overdue patients returned to care after a call
monthly_overdue_patients.returned_after_call,
monthly_overdue_patients.returned_after_call * 100.0 / nullif(called, 0) as percentage_returned_after_call,

monthly_overdue_patients.filtered_returned_after_call,
monthly_overdue_patients.filtered_returned_after_call * 100.0 / nullif(filtered_called, 0) as filtered_percentage_returned_after_call,

-- monthly overdue patients returned to care after a call grouped by call result
monthly_overdue_patients.returned_after_call_with_result_agreed_to_visit,
monthly_overdue_patients.returned_after_call_with_result_agreed_to_visit * 100.0 / nullif(called_with_result_agreed_to_visit, 0) as percentage_returned_after_call_with_result_agreed_to_visit,

monthly_overdue_patients.returned_after_call_with_result_remind_to_call_later,
monthly_overdue_patients.returned_after_call_with_result_remind_to_call_later * 100.0 / nullif(called_with_result_remind_to_call_later, 0) as percentage_returned_after_call_with_result_remind_to_call_later,

monthly_overdue_patients.returned_after_call_with_result_remove_from_overdue_list,
monthly_overdue_patients.returned_after_call_with_result_remove_from_overdue_list * 100.0 / nullif(called_with_result_remove_from_overdue_list, 0) as percentage_returned_after_call_with_result_remove_from_overdue_list,

monthly_overdue_patients.filtered_returned_after_call_with_result_agreed_to_visit,
monthly_overdue_patients.filtered_returned_after_call_with_result_agreed_to_visit * 100.0 / nullif(filtered_called_with_result_agreed_to_visit, 0) as filtered_percentage_returned_after_call_with_result_agreed_to_visit,

monthly_overdue_patients.filtered_returned_after_call_with_result_remind_to_call_later,
monthly_overdue_patients.filtered_returned_after_call_with_result_remind_to_call_later * 100.0 / nullif(filtered_called_with_result_remind_to_call_later, 0) as filtered_percentage_returned_after_call_with_result_remind_to_call_later,

monthly_overdue_patients.filtered_returned_after_call_with_result_remove_from_overdue_list,
monthly_overdue_patients.filtered_returned_after_call_with_result_remove_from_overdue_list * 100.0 / nullif(filtered_called_with_result_remove_from_overdue_list, 0) as filtered_percentage_returned_after_call_with_result_remove_from_overdue_list

FROM reporting_facilities rf
INNER JOIN reporting_months cal
-- ensure a row for every facility and month combination
    ON TRUE
LEFT OUTER JOIN registered_patients
    ON registered_patients.month_date = cal.month_date
    AND registered_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN registered_diabetes_patients
    ON registered_diabetes_patients.month_date = cal.month_date
    AND registered_diabetes_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN registered_hypertension_and_diabetes_patients
    ON registered_hypertension_and_diabetes_patients.month_date = cal.month_date
    AND registered_hypertension_and_diabetes_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN assigned_patients
    ON assigned_patients.month_date = cal.month_date
    AND assigned_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN assigned_diabetes_patients
    ON assigned_diabetes_patients.month_date = cal.month_date
    AND assigned_diabetes_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN adjusted_outcomes
    ON adjusted_outcomes.month_date = cal.month_date
    AND adjusted_outcomes.region_id = rf.facility_region_id
LEFT OUTER JOIN adjusted_diabetes_outcomes
    ON adjusted_diabetes_outcomes.month_date = cal.month_date
    AND adjusted_diabetes_outcomes.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_cohort_outcomes
    ON monthly_cohort_outcomes.month_date = cal.month_date
    AND monthly_cohort_outcomes.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_overdue_calls
    ON monthly_overdue_calls.month_date = cal.month_date
    AND monthly_overdue_calls.region_id = rf.facility_region_id
LEFT OUTER JOIN monthly_follow_ups
    ON monthly_follow_ups.month_date = cal.month_date
    AND monthly_follow_ups.facility_id = rf.facility_id
LEFT OUTER JOIN monthly_diabetes_follow_ups
    ON monthly_diabetes_follow_ups.month_date = cal.month_date
    AND monthly_diabetes_follow_ups.facility_id = rf.facility_id
LEFT OUTER JOIN reporting_facility_appointment_scheduled_days
    ON reporting_facility_appointment_scheduled_days.month_date = cal.month_date
    AND reporting_facility_appointment_scheduled_days.facility_id = rf.facility_id
LEFT OUTER JOIN monthly_overdue_patients
    ON  monthly_overdue_patients.month_date = cal.month_date
    AND monthly_overdue_patients.region_id = rf.facility_region_id
