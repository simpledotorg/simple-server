select distinct on (reporting_patient_states.month_date, reporting_patient_states.patient_id)
    reporting_patient_states.month_date as month_date,
    reporting_patient_states.patient_id as patient_id,
    reporting_patient_states.assigned_facility_id as assigned_facility_id,
    reporting_patient_states.assigned_facility_region_id as assigned_facility_region_id,
    appointments.id as previous_appointment_id,
    appointments.device_created_at as previous_appointment_date,
    appointments.scheduled_date as previous_appointment_scheduled_date,
    visits.visited_at_after_appointment as visited_at_after_appointment,
    next_call_results.device_created_at as next_called_at,
    previous_call_results.device_created_at as previous_called_at,
    reporting_patient_states.hypertension as hypertension,
    reporting_patient_states.diabetes as diabetes,
    next_call_results.result_type as next_call_result_type,
    next_call_results.remove_reason as next_call_remove_from_overdue_list_reason,
    previous_call_results.result_type as previous_call_result_type,
    previous_call_results.remove_reason as previous_call_remove_from_overdue_list_reason,
    case
        when (appointments.scheduled_date >= reporting_patient_states.month_date) then 'no'
        when (appointments.scheduled_date < reporting_patient_states.month_date and visits.visited_at_after_appointment < reporting_patient_states.month_date) then 'no'
        else 'yes'
        end as is_overdue,
    case
        when next_call_results.device_created_at is null then 'no'
        else 'yes'
        end as has_called,
    case
        when visited_at_after_appointment is null or next_call_results.device_created_at is null then 'no'
        when visited_at_after_appointment > next_call_results.device_created_at + interval '15 days' then 'no'
        else 'yes'
        end as has_visited_following_call,
    case
        when reporting_patient_states.htn_care_state = 'lost_to_follow_up' then 'yes'
        else 'no'
        end as ltfu,
    case
        when reporting_patient_states.htn_care_state = 'under_care' then 'yes'
        else 'no'
        end as under_care,
    case
        when patient_phone_numbers.number is null then 'no'
        else 'yes'
        end as has_phone,
    case
        when previous_call_results.result_type = 'removed_from_overdue_list' then 'yes'
        else 'no'
        end as removed_from_overdue_list,
    case
        when next_call_results.result_type = 'removed_from_overdue_list' then 'yes'
        else 'no'
        end as removed_from_overdue_list_during_the_month
from reporting_patient_states
left join appointments on reporting_patient_states.patient_id = appointments.patient_id and appointments.device_created_at < reporting_patient_states.month_date
left join patient_phone_numbers on patient_phone_numbers.patient_id = reporting_patient_states.patient_id
left join lateral (
    -- Merging BS, BP, Appointments & PD
    select id as visit_id, patient_id, recorded_at as visited_at_after_appointment, 'Blood Sugar' as visit_type
    from blood_sugars
    where
        deleted_at is null
      and patient_id = reporting_patient_states.patient_id
      and appointments.device_created_at < blood_sugars.recorded_at
    union (select id as visit_id, patient_id, recorded_at as visited_at_after_appointment, 'Blood Pressure' as visit_type
           from blood_pressures
           where deleted_at is null
             and patient_id = reporting_patient_states.patient_id
             and appointments.device_created_at < blood_pressures.recorded_at)
    union (select id as visit_id, patient_id, device_created_at as visited_at_after_appointment, 'Appointments' as visit_type
           from appointments as appointments_visit
           where deleted_at is null
             and patient_id = reporting_patient_states.patient_id
             and appointments.device_created_at < appointments_visit.device_created_at)
    union (select id as visit_id, patient_id, device_created_at as visited_at_after_appointment , 'Prescription Drugs' as visit_type
           from prescription_drugs
           where deleted_at is null
             and patient_id = reporting_patient_states.patient_id
             and appointments.device_created_at < prescription_drugs.device_created_at)
    ) visits on reporting_patient_states.patient_id = visits.patient_id
 left join call_results as previous_call_results
           on reporting_patient_states.patient_id = previous_call_results.patient_id
               and previous_call_results.device_created_at < reporting_patient_states.month_date
               and previous_call_results.device_created_at > appointments.scheduled_date
 full join call_results as next_call_results
           on reporting_patient_states.patient_id = next_call_results.patient_id
               and next_call_results.device_created_at >= reporting_patient_states.month_date
               and next_call_results.device_created_at < reporting_patient_states.month_date + interval '1 month'
where reporting_patient_states.status <> 'dead'
order by reporting_patient_states.month_date, reporting_patient_states.patient_id, appointments.device_created_at desc, visits.visited_at_after_appointment, next_call_results.device_created_at, previous_call_results.device_created_at desc