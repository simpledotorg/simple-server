WITH latest_appointments_per_patient_per_month AS (
    SELECT DISTINCT ON (patient_id, month_date) a.*,
        to_char(a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date
    FROM appointments a
    INNER JOIN patients p ON p.id = a.patient_id
    WHERE extract('days' FROM (a.scheduled_date - a.device_created_at))::integer >= 0
      AND a.device_created_at >= DATE_TRUNC('month', (now() AT TIME ZONE 'UTC') - INTERVAL '6 months')
      AND date_trunc('month', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
          > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      AND p.deleted_at IS NULL and a.deleted_at IS NULL
    ORDER BY a.patient_id, month_date, a.device_created_at desc
),
 scheduled_days_distribution AS (
     SELECT month_date,
            width_bucket(extract('days' FROM (scheduled_date - device_created_at))::integer, array[0, 15, 30, 60]) bucket,
            COUNT(*) number_of_appointments,
            creation_facility_id facility_id
     FROM latest_appointments_per_patient_per_month
     GROUP BY bucket, creation_facility_id, month_date
)

SELECT facility_id,
       month_date,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 1))::integer AS appts_scheduled_0_to_14_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 2))::integer AS appts_scheduled_15_to_30_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 3))::integer AS appts_scheduled_31_to_60_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 4))::integer AS appts_scheduled_more_than_60_days,
       SUM(number_of_appointments)::integer total_appts_scheduled
FROM scheduled_days_distribution
GROUP BY facility_id, month_date
