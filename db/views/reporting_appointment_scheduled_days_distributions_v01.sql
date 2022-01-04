WITH scheduled_days_distribution AS (
  SELECT to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date,
         width_bucket(extract('days' FROM (scheduled_date - device_created_at))::integer, array[0, 15, 30, 60]) bucket,
         COUNT(*) number_of_appointments,
         creation_facility_id facility_id
  FROM appointments
  WHERE extract('days' FROM (scheduled_date - device_created_at))::integer >= 0
  AND device_created_at >= DATE_TRUNC('month', (now() AT TIME ZONE 'UTC') - INTERVAL '6 months')
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
