 SELECT bp.id AS bp_id,
    bp.systolic,
    bp.diastolic,
    bp.created_at,
    bp.updated_at,
    bp.device_created_at AS visit_date,
    bp.facility_id,
    bp.user_id,
    p.id AS patient_id,
    p.full_name,
    p.age,
    p.gender,
    p.date_of_birth,
    p.status AS patient_status,
    p.address_id,
    p.device_created_at AS registration_date,
    a.street_address,
    a.village_or_colony,
    a.district,
    a.state,
    a.country,
    a.pin,
    f.name AS facility_name,
    f.facility_type,
    f.latitude,
    f.longitude,
    u.full_name AS user_name,
    pn.number AS phone_number,
    pn.phone_type,
    pd.id AS drug_id,
    pd.name AS drug_name,
    pd.rxnorm_code,
    pd.dosage,
    pd.is_protocol_drug,
    pd.is_deleted
   FROM patients p
     JOIN blood_pressures bp ON p.id = bp.patient_id
     JOIN facilities f ON f.id = bp.facility_id
     JOIN addresses a ON p.address_id = a.id
     JOIN users u ON u.id = bp.user_id
     LEFT JOIN patient_phone_numbers pn ON pn.patient_id = p.id
     LEFT JOIN prescription_drugs pd ON bp.patient_id = pd.patient_id AND date_trunc('day'::text, bp.device_created_at) = date_trunc('day'::text, pd.device_created_at);
