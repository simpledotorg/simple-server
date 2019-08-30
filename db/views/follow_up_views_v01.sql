 SELECT ap.id,
    ap.patient_id,
    ap.facility_id,
    ap.scheduled_date,
    ap.status,
    ap.cancel_reason,
    ap.device_created_at,
    ap.device_updated_at,
    ap.created_at,
    ap.updated_at,
    ap.remind_on,
    ap.agreed_to_visit,
    date_part('day'::text, lead(ap.device_created_at, 1) OVER (PARTITION BY ap.patient_id ORDER BY ap.scheduled_date) - ap.scheduled_date::timestamp without time zone) AS follow_up_delta,
    f.name AS facility_name,
    f.facility_type,
    f.latitude,
    f.longitude
   FROM appointments ap
     JOIN facilities f ON ap.facility_id = f.id;
