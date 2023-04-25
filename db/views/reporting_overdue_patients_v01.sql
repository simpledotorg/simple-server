SELECT DISTINCT ON (reporting_patient_states.month_date, reporting_patient_states.patient_id)
  reporting_patient_states.month_date AS month_date,
  reporting_patient_states.patient_id AS patient_id,
  reporting_patient_states.assigned_facility_id AS assigned_facility_id,
  reporting_patient_states.assigned_facility_region_id AS assigned_facility_region_id,
  appointments.id AS previous_appointment_id,
  appointments.device_created_at AS previous_appointment_date,
  appointments.scheduled_date AS previous_appointment_scheduled_date,
  visits.visited_at_after_appointment AS visited_at_after_appointment,
  next_call_results.device_created_at AS next_called_at,
  previous_call_results.device_created_at AS previous_called_at,
  reporting_patient_states.hypertension AS hypertension,
  reporting_patient_states.diabetes AS diabetes,
  next_call_results.result_type AS next_call_result_type,
  next_call_results.remove_reason AS next_call_remove_from_overdue_list_reason,
  previous_call_results.result_type AS previous_call_result_type,
  previous_call_results.remove_reason AS previous_call_remove_from_overdue_list_reason,
  CASE
    WHEN (appointments.scheduled_date >= reporting_patient_states.month_date) THEN 'no'
    WHEN (appointments.scheduled_date < reporting_patient_states.month_date
	AND visits.visited_at_after_appointment < reporting_patient_states.month_date) THEN 'no'
    ELSE 'yes'
  END AS is_overdue,
  CASE
    WHEN next_call_results.device_created_at IS NULL THEN 'no'
    ELSE 'yes'
  END AS has_called,
  CASE
    WHEN visited_at_after_appointment IS NULL OR next_call_results.device_created_at IS NULL THEN 'no'
    WHEN visited_at_after_appointment > next_call_results.device_created_at + interval '15 days' THEN 'no'
    ELSE 'yes'
  END AS has_visited_following_call,
  CASE
    WHEN reporting_patient_states.htn_care_state = 'lost_to_follow_up' THEN 'yes'
    ELSE 'no'
  END AS ltfu,
  CASE
    WHEN reporting_patient_states.htn_care_state = 'under_care' THEN 'yes'
    ELSE 'no'
  END AS under_care,
  CASE
    WHEN patient_phone_numbers.number IS NULL THEN 'no'
    ELSE 'yes'
  END AS has_phone,
  CASE
    WHEN previous_call_results.result_type = 'removed_from_overdue_list' THEN 'yes'
    ELSE 'no'
  END AS removed_from_overdue_list
FROM reporting_patient_states
  LEFT JOIN appointments ON reporting_patient_states.patient_id = appointments.patient_id
  AND appointments.device_created_at < reporting_patient_states.month_date
  LEFT JOIN patient_phone_numbers ON patient_phone_numbers.patient_id = reporting_patient_states.patient_id
  LEFT JOIN lateral (
    -- Merging BS, BP, Appointments & PD
    SELECT id AS visit_id, patient_id, recorded_at AS visited_at_after_appointment, 'Blood Sugar' AS visit_type
    FROM blood_sugars
    WHERE deleted_at IS NULL AND patient_id = reporting_patient_states.patient_id AND appointments.device_created_at < blood_sugars.recorded_at
    UNION
      (SELECT id AS visit_id, patient_id, recorded_at AS visited_at_after_appointment, 'Blood Pressure' AS visit_type
        FROM blood_pressures
        WHERE deleted_at IS NULL AND patient_id = reporting_patient_states.patient_id AND appointments.device_created_at < blood_pressures.recorded_at)
    UNION
      (SELECT id AS visit_id, patient_id, device_created_at AS visited_at_after_appointment, 'Appointments' AS visit_type
        FROM appointments AS appointments_visit
        WHERE deleted_at IS NULL AND patient_id = reporting_patient_states.patient_id AND appointments.device_created_at < appointments_visit.device_created_at)
    UNION
      (SELECT id AS visit_id, patient_id, device_created_at AS visited_at_after_appointment, 'Prescription Drugs' AS visit_type
        FROM prescription_drugs
        WHERE deleted_at IS NULL AND patient_id = reporting_patient_states.patient_id AND appointments.device_created_at < prescription_drugs.device_created_at)
  ) visits ON reporting_patient_states.patient_id = visits.patient_id
  -- Used to determine if the patient was removed from overdue list at the beginning of the month
  LEFT JOIN call_results AS previous_call_results
    ON reporting_patient_states.patient_id = previous_call_results.patient_id
      AND previous_call_results.device_created_at < reporting_patient_states.month_date
      AND previous_call_results.device_created_at > appointments.scheduled_date FULL
  -- Used to determine the outcome of a call and how it affects the rate of patients returing to care
  JOIN call_results AS next_call_results
    ON reporting_patient_states.patient_id = next_call_results.patient_id
      AND next_call_results.device_created_at >= reporting_patient_states.month_date
      AND next_call_results.device_created_at < reporting_patient_states.month_date + interval '1 month'
WHERE
  reporting_patient_states.status <> 'dead'
ORDER BY
  reporting_patient_states.month_date,
  reporting_patient_states.patient_id,
  appointments.device_created_at DESC,
  visits.visited_at_after_appointment,
  next_call_results.device_created_at,
  previous_call_results.device_created_at DESC
