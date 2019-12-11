SELECT
p.recorded_at,
CONCAT(date_part('year', p.recorded_at), ' Q', EXTRACT(QUARTER FROM p.recorded_at)) AS quarter,
p.full_name,
(
    CASE
      WHEN p.date_of_birth IS NOT NULL THEN date_part('year', age(p.date_of_birth))
      ELSE p.age + date_part('year', NOW()) - date_part('year', p.age_updated_at)
    END
) AS current_age,
p.gender,
latest_phone_number.number,
addresses.village_or_colony,
addresses.district,
addresses.state,
reg_facility.name AS registration_facility_name,
reg_facility.facility_type AS registration_facility_type,
reg_facility.district AS registration_district,
reg_facility.state AS registration_state,
latest_bp.systolic AS latest_bp_systolic,
latest_bp.diastolic AS latest_bp_diastolic,
latest_bp.recorded_at AS latest_bp_recorded_at,
CONCAT(date_part('year', latest_bp.recorded_at), ' Q', EXTRACT(QUARTER FROM latest_bp.recorded_at)) AS latest_bp_quarter,
latest_bp_facility.name AS latest_bp_facility_name,
latest_bp_facility.facility_type AS latest_bp_facility_type,
latest_bp_facility.district AS latest_bp_district,
latest_bp_facility.state AS latest_bp_state,
greatest(0, date_part('day', NOW() - next_appointment.scheduled_date)) AS days_overdue,
next_appointment.scheduled_date AS next_appointment_scheduled_date,
next_appointment_facility.name AS next_appointment_facility_name,
next_appointment_facility.facility_type AS next_appointment_facility_type,
next_appointment_facility.district AS next_appointment_district,
next_appointment_facility.state AS next_appointment_state,

(
    CASE
      WHEN (latest_bp.systolic >= 180 OR latest_bp.diastolic >= 110) THEN 0
      WHEN mh.prior_heart_attack = 'yes'
        OR mh.prior_stroke = 'yes'
        OR mh.diabetes = 'yes'
        OR mh.chronic_kidney_disease = 'yes'
        THEN 1
      WHEN (latest_bp.systolic BETWEEN 160 AND 179) OR (latest_bp.diastolic BETWEEN 100 AND 109) THEN 2
      WHEN (latest_bp.systolic BETWEEN 140 AND 159) OR (latest_bp.diastolic BETWEEN 90 AND 99) THEN 3
      WHEN (latest_bp.systolic <= 140 AND latest_bp.diastolic <= 90) THEN 4
      ELSE 5
    END
) AS risk_level,

latest_bp_passport.identifier AS latest_bp_passport,
p.id

FROM patients p

LEFT OUTER JOIN addresses ON addresses.id = p.address_id
LEFT OUTER JOIN facilities reg_facility ON reg_facility.id = p.registration_facility_id
LEFT OUTER JOIN medical_histories mh ON mh.patient_id = p.id

LEFT OUTER JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM patient_phone_numbers
    ORDER BY patient_id, device_created_at DESC
) AS latest_phone_number
ON latest_phone_number.patient_id = p.id

LEFT OUTER JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM blood_pressures
    ORDER BY patient_id, recorded_at DESC
) AS latest_bp
ON latest_bp.patient_id = p.id
LEFT OUTER JOIN facilities latest_bp_facility ON latest_bp_facility.id = latest_bp.facility_id

LEFT OUTER JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM patient_business_identifiers
    WHERE identifier_type = 'simple_bp_passport'
    ORDER BY patient_id, device_created_at DESC
) AS latest_bp_passport
ON latest_bp_passport.patient_id = p.id

LEFT OUTER JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM appointments
    ORDER BY patient_id, scheduled_date DESC
) AS next_appointment
ON next_appointment.patient_id = p.id
LEFT OUTER JOIN facilities next_appointment_facility ON next_appointment_facility.id = next_appointment.facility_id;
