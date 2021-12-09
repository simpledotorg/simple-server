-- Only most recent call result per patient per month.
SELECT DISTINCT ON (a.patient_id, cal.month_date)
    cal.month_date,
    cal.month_string,
    cal.month,
    cal.quarter,
    cal.year,
    cr.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')) AS call_result_created_at,
    cr.id AS call_result_id,
    cr.user_id AS user_id,
    a.id AS appointment_id,
    a.facility_id AS appointment_facility_id,
    a.patient_id AS patient_id,
    appointment_facility.facility_size as appointment_facility_size,
    appointment_facility.facility_type as appointment_facility_type,
    appointment_facility.facility_region_slug as appointment_facility_slug,
    appointment_facility.facility_region_id as appointment_facility_region_id,
    appointment_facility.block_slug as appointment_block_slug,
    appointment_facility.block_region_id as appointment_block_region_id,
    appointment_facility.district_slug as appointment_district_slug,
    appointment_facility.district_region_id as appointment_district_region_id,
    appointment_facility.state_slug as appointment_state_slug,
    appointment_facility.state_region_id as appointment_state_region_id,
    appointment_facility.organization_slug as appointment_organization_slug,
    appointment_facility.organization_region_id as appointment_organization_region_id

FROM call_results cr
-- Only fetch call results that happened during the selected calendar month
-- We use year and month comparisons to avoid timezone errors
INNER JOIN reporting_months cal
    ON to_char(cr.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') = to_char(cal.month_date, 'YYYY-MM')
INNER JOIN appointments a ON cr.appointment_id = a.id AND a.deleted_at IS NULL
INNER JOIN reporting_facilities appointment_facility ON a.facility_id = appointment_facility.facility_id
WHERE cr.deleted_at IS NULL
ORDER BY
-- Ensure most recent cr is fetched
a.patient_id,
cal.month_date,
cr.device_created_at DESC
