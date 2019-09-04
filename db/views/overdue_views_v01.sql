 SELECT ap.id AS appointment_id,
    ap.facility_id,
    ap.scheduled_date,
    ap.status AS appointment_status,
    ap.cancel_reason,
    ap.device_created_at,
    ap.device_updated_at,
    ap.created_at,
    ap.updated_at,
    ap.remind_on,
    ap.agreed_to_visit,
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
    f.longitude
   FROM appointments ap
     JOIN patients p ON p.id = ap.patient_id
     JOIN facilities f ON f.id = ap.facility_id
     JOIN addresses a ON p.address_id = a.id
     LEFT JOIN patient_phone_numbers pn ON pn.patient_id = p.id;
