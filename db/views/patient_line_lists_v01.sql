SELECT
p.recorded_at,
CONCAT(date_part('year', p.recorded_at), ' Q', EXTRACT(QUARTER FROM p.recorded_at)) as quarter,
p.full_name,
(
    CASE
      WHEN p.date_of_birth IS NOT NULL THEN date_part('year', age(p.date_of_birth))
      ELSE p.age + date_part('year', NOW()) - date_part('year', p.age_updated_at)
    END
) as current_age,
p.gender,
newest_phone_number.number,
addresses.village_or_colony,
addresses.district,
addresses.state,
reg_facility.name,
reg_facility.facility_type,
reg_facility.district,
reg_facility.state,
newest_bp.systolic,
newest_bp.diastolic,
newest_bp.recorded_at,
CONCAT(date_part('year', newest_bp.recorded_at), ' Q', EXTRACT(QUARTER FROM newest_bp.recorded_at)) as newest_bp_quarter,
newest_bp_facility.name,
newest_bp_facility.facility_type,
newest_bp_facility.district,
newest_bp_facility.state,
greatest(0, date_part('day', NOW() - next_appointment.scheduled_date)) as days_overdue,
next_appointment.scheduled_date,
next_appointment_facility.name,
next_appointment_facility.facility_type,
next_appointment_facility.district,
next_appointment_facility.state,

(
    CASE
      WHEN (newest_bp.systolic >= 180 OR newest_bp.diastolic >= 110) THEN 0
      WHEN mh.prior_heart_attack = 'yes'
        OR mh.prior_stroke = 'yes'
        OR mh.diabetes = 'yes'
        OR mh.chronic_kidney_disease = 'yes'
        THEN 1
      WHEN (newest_bp.systolic BETWEEN 160 AND 179) OR (newest_bp.diastolic BETWEEN 100 AND 109) THEN 2
      WHEN (newest_bp.systolic BETWEEN 140 AND 159) OR (newest_bp.diastolic BETWEEN 90 AND 99) THEN 3
      WHEN (newest_bp.systolic <= 140 AND newest_bp.diastolic <= 90) THEN 4
      ELSE 5
    END
) AS risk_level,

newest_bp_passport.identifier as bp_passport,
p.id

FROM patients p

JOIN addresses ON addresses.id = p.address_id
JOIN facilities reg_facility ON reg_facility.id = p.registration_facility_id
JOIN medical_histories mh ON mh.patient_id = p.id

JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM patient_phone_numbers
    ORDER BY patient_id, device_created_at DESC
) as newest_phone_number
ON newest_phone_number.patient_id = p.id

JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM patient_business_identifiers
    WHERE identifier_type = 'simple_bp_passport'
    ORDER BY patient_id, device_created_at DESC
) as newest_bp_passport
ON newest_bp_passport.patient_id = p.id

JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM blood_pressures
    ORDER BY patient_id, recorded_at DESC
) as newest_bp
ON newest_bp.patient_id = p.id
JOIN facilities newest_bp_facility ON newest_bp_facility.id = newest_bp.facility_id

JOIN (
    SELECT DISTINCT ON (patient_id) *
    FROM appointments
    ORDER BY patient_id, scheduled_date DESC
) as next_appointment
ON next_appointment.patient_id = p.id
JOIN facilities next_appointment_facility ON next_appointment_facility.id = next_appointment.facility_id;
