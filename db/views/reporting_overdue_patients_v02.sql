WITH patients_with_appointments AS (
    SELECT
        DISTINCT ON (rps.patient_id, rps.month_date) 
	rps.month_date,
        rps.patient_id,
        rps.hypertension AS hypertension,
        rps.diabetes AS diabetes,
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
    FROM
        reporting_patient_states rps
        LEFT JOIN appointments ON appointments.patient_id = rps.patient_id
        AND appointments.device_created_at < rps.month_date
    WHERE
        rps.status <> 'dead'
        AND rps.month_date > NOW() - INTERVAL '24 months'
    ORDER BY
        rps.patient_id,
        rps.month_date,
        appointments.device_created_at DESC
),

patients_with_appointments_and_visits AS (
    SELECT
        patients_with_appointments.*,
        visit_id,
        visited_at_after_appointment
    FROM
        patients_with_appointments
        LEFT JOIN lateral (
            SELECT
                DISTINCT ON (patient_id) id AS visit_id,
                patient_id,
                recorded_at AS visited_at_after_appointment
            FROM
                blood_sugars
            WHERE
                deleted_at IS NULL
                AND patient_id = patients_with_appointments.patient_id
                AND patients_with_appointments.previous_appointment_date < blood_sugars.recorded_at
                AND blood_sugars.recorded_at < patients_with_appointments.month_date + INTERVAL '1 month' + INTERVAL '15 days'
            UNION ALL (
                SELECT
                    id AS visit_id,
                    patient_id,
                    recorded_at AS visited_at_after_appointment
                FROM
                    blood_pressures
                WHERE
                    deleted_at IS NULL
                    AND patient_id = patients_with_appointments.patient_id
                    AND patients_with_appointments.previous_appointment_date < blood_pressures.recorded_at
                    AND blood_pressures.recorded_at < patients_with_appointments.month_date + INTERVAL '1 month' + INTERVAL '15 days'
            )
            UNION ALL (
                SELECT
                    id AS visit_id,
                    patient_id,
                    device_created_at AS visited_at_after_appointment
                FROM
                    appointments AS patients_with_appointments_visit
                WHERE
                    deleted_at IS NULL
                    AND patient_id = patients_with_appointments.patient_id
                    AND patients_with_appointments.previous_appointment_date < patients_with_appointments_visit.device_created_at
                    AND patients_with_appointments_visit.device_created_at < patients_with_appointments.month_date + INTERVAL '1 month' + INTERVAL '15 days'
            )
            UNION ALL (
                SELECT
                    id AS visit_id,
                    patient_id,
                    device_created_at AS visited_at_after_appointment
                FROM
                    prescription_drugs
                WHERE
                    deleted_at IS NULL
                    AND patient_id = patients_with_appointments.patient_id
                    AND patients_with_appointments.previous_appointment_date < prescription_drugs.device_created_at
                    AND prescription_drugs.device_created_at < patients_with_appointments.month_date + INTERVAL '1 month' + INTERVAL '15 days'
            )
            ORDER BY
                patient_id,
                visited_at_after_appointment
        ) AS visits ON patients_with_appointments.patient_id = visits.patient_id
),

patient_with_call_results AS (
    SELECT
        DISTINCT ON (
            patients_with_appointments_and_visits.patient_id,
            patients_with_appointments_and_visits.month_date
        ) patients_with_appointments_and_visits.*,
        previous_call_results.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS previous_called_at,
        previous_call_results.result_type AS previous_call_result_type,
        previous_call_results.remove_reason AS previous_call_removed_from_overdue_list_reason,
        next_call_results.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS next_called_at,
        next_call_results.result_type AS next_call_result_type,
        next_call_results.remove_reason as next_call_removed_from_overdue_list_reason,
        next_call_results.user_id AS called_by_user_id
    FROM
        patients_with_appointments_and_visits
        LEFT JOIN call_results previous_call_results ON patients_with_appointments_and_visits.patient_id = previous_call_results.patient_id
        AND previous_call_results.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
            SELECT
                current_setting('TIMEZONE')
        ) < patients_with_appointments_and_visits.month_date
        AND previous_call_results.device_created_at > previous_appointment_schedule_date
        LEFT JOIN call_results next_call_results ON patients_with_appointments_and_visits.patient_id = next_call_results.patient_id
        AND next_call_results.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
            SELECT
                current_setting('TIMEZONE')
        ) >= patients_with_appointments_and_visits.month_date
        AND next_call_results.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
            SELECT
                current_setting('TIMEZONE')
        ) < patients_with_appointments_and_visits.month_date + INTERVAL '1 month'
    ORDER BY
        patients_with_appointments_and_visits.patient_id,
        patients_with_appointments_and_visits.month_date,
        next_call_results.device_created_at,
        previous_call_results.device_created_at DESC
),

patient_with_call_results_and_phone AS (
    SELECT
        DISTINCT ON (
            patient_with_call_results.patient_id,
            patient_with_call_results.month_date
        ) patient_with_call_results.*,
        patient_phone_numbers.number AS patient_phone_number
    FROM
        patient_with_call_results
        LEFT JOIN patient_phone_numbers ON patient_phone_numbers.patient_id = patient_with_call_results.patient_id
    ORDER BY
        patient_with_call_results.patient_id,
        patient_with_call_results.month_date
)

SELECT
    month_date,
    patient_id,
    hypertension,
    diabetes,
    htn_care_state,
    month,
    quarter,
    year,
    month_string,
    quarter_string,
    assigned_facility_id,
    assigned_facility_slug,
    assigned_facility_region_id,
    assigned_block_slug,
    assigned_block_region_id,
    assigned_district_slug,
    assigned_district_region_id,
    assigned_state_slug,
    assigned_state_region_id,
    assigned_organization_slug,
    assigned_organization_region_id,
    previous_appointment_id,
    previous_appointment_date,
    previous_appointment_schedule_date,
    visited_at_after_appointment,
    called_by_user_id,
    next_called_at,
    previous_called_at,
    next_call_result_type,
    next_call_removed_from_overdue_list_reason,
    previous_call_result_type,
    previous_call_removed_from_overdue_list_reason,
    CASE
        WHEN previous_appointment_id IS NULL THEN 'no'
        WHEN (previous_appointment_schedule_date >= month_date) THEN 'no'
        WHEN (
            previous_appointment_schedule_date < month_date
            and visited_at_after_appointment < month_date
        ) THEN 'no'
        ELSE 'yes'
    END AS is_overdue,
    CASE
        WHEN next_called_at IS NULL THEN 'no'
        ELSE 'yes'
    END AS has_called,
    CASE
        WHEN visited_at_after_appointment IS NULL
        OR next_called_at IS NULL THEN 'no'
        WHEN visited_at_after_appointment > next_called_at + INTERVAL '15 days' THEN 'no'
        ELSE 'yes'
    END AS has_visited_following_call,
    CASE
        WHEN htn_care_state = 'lost_to_follow_up' THEN 'yes'
        ELSE 'no'
    END AS ltfu,
    CASE
        WHEN htn_care_state = 'under_care' THEN 'yes'
        ELSE 'no'
    END AS under_care,
    CASE
        WHEN patient_phone_number IS NULL THEN 'no'
        ELSE 'yes'
    END AS has_phone,
    CASE
        WHEN previous_call_result_type = 'removed_from_overdue_list' THEN 'yes'
        ELSE 'no'
    END AS removed_from_overdue_list,
    CASE
        WHEN next_call_result_type = 'removed_from_overdue_list' THEN 'yes'
        ELSE 'no'
    END AS removed_from_overdue_list_during_the_month
FROM
    patient_with_call_results_and_phone;
