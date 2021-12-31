WITH appointments_with_scheduled_days AS (
  SELECT creation_facility_id,
         extract('days' FROM (scheduled_date - device_created_at))::integer scheduled_days,
         to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date
  FROM appointments
  WHERE extract('days' FROM (scheduled_date - device_created_at))::integer >= 0
  AND device_created_at >= DATE_TRUNC('month', (now() AT TIME ZONE 'UTC') - INTERVAL '3 months')
),

scheduled_days_distribution AS (
  SELECT month_date,
         (CASE width_bucket(scheduled_days, array[0, 15, 30, 60])
            WHEN 1 THEN '0-14 days'
            WHEN 2 THEN '15-30 days'
            WHEN 3 THEN '31-60 days'
            WHEN 4 THEN '60+ days'
           END)   bucket_label,
         COUNT(*) number_of_appointments,
         creation_facility_id
  FROM appointments_with_scheduled_days
  GROUP BY bucket_label, creation_facility_id, month_date
)

SELECT creation_facility_id facility_id,
  month_date,
  jsonb_object_agg(bucket_label, number_of_appointments) appointments_by_range,
  SUM(number_of_appointments)::integer total_appointments_in_month
FROM scheduled_days_distribution
GROUP BY facility_id, month_date
