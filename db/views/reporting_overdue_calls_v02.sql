SELECT DISTINCT ON (a.patient_id, cal.month_date) cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    timezone('UTC'::text, timezone('UTC'::text, cr.device_created_at)) AS call_result_created_at,
    cr.id AS call_result_id,
    cr.user_id,
    a.id AS appointment_id,
    a.facility_id AS appointment_facility_id,
    a.patient_id,
    appointment_facility.facility_size AS appointment_facility_size,
    appointment_facility.facility_type AS appointment_facility_type,
    appointment_facility.facility_region_slug AS appointment_facility_slug,
    appointment_facility.facility_region_id AS appointment_facility_region_id,
    appointment_facility.block_slug AS appointment_block_slug,
    appointment_facility.block_region_id AS appointment_block_region_id,
    appointment_facility.district_slug AS appointment_district_slug,
    appointment_facility.district_region_id AS appointment_district_region_id,
    appointment_facility.state_slug AS appointment_state_slug,
    appointment_facility.state_region_id AS appointment_state_region_id,
    appointment_facility.organization_slug AS appointment_organization_slug,
    appointment_facility.organization_region_id AS appointment_organization_region_id
FROM (((public.call_results cr
    JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, cr.device_created_at)), 'YYYY-MM'::text) = to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))))
    JOIN public.appointments a ON (((cr.appointment_id = a.id) AND (a.deleted_at IS NULL))))
    JOIN public.patients p ON (p.id = a.patient_id AND ((p.deleted_at IS NULL) AND (p.diagnosed_confirmed_at IS NOT NULL)))
    JOIN public.reporting_facilities appointment_facility ON ((a.facility_id = appointment_facility.facility_id)))
WHERE (cr.deleted_at IS NULL)
ORDER BY a.patient_id, cal.month_date, cr.device_created_at DESC;