WITH latest_medical_histories AS (
    SELECT DISTINCT ON (patient_id) mh.*
    FROM medical_histories mh
    WHERE  mh.deleted_at IS NULL
    ORDER BY patient_id, mh.device_created_at DESC
),
 latest_appointments_per_patient_per_month AS (
    SELECT DISTINCT ON (patient_id, month_date) a.*,
        lmh.hypertension,
        lmh.diabetes,
        to_char(a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM-01')::date month_date
    FROM appointments a
    INNER JOIN patients p ON p.id = a.patient_id
    INNER JOIN latest_medical_histories lmh ON lmh.patient_id = a.patient_id
    WHERE a.scheduled_date >= date_trunc('day', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      AND a.device_created_at >= date_trunc('month', (now() AT TIME ZONE 'UTC') - INTERVAL '6 months')
      AND date_trunc('month', a.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
          > date_trunc('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))
      AND p.deleted_at IS NULL and a.deleted_at IS NULL
      AND (lmh.hypertension = 'yes'  OR lmh.diabetes = 'yes')
    ORDER BY a.patient_id, month_date, a.device_created_at desc
),
 scheduled_days_distribution AS (
     SELECT month_date,
            width_bucket(
              extract('days' FROM (scheduled_date - date_trunc('day', device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))))::integer,
              array[0, 15, 32, 63]
            ) bucket,
            COUNT(*) number_of_appointments,
            hypertension,
            diabetes,
            creation_facility_id facility_id
     FROM latest_appointments_per_patient_per_month
     GROUP BY bucket, creation_facility_id, month_date, hypertension, diabetes)

SELECT facility_id,
       month_date,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_0_to_14_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_15_to_31_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_32_to_62_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND hypertension = 'yes'))::integer AS htn_appts_scheduled_more_than_62_days,
       (SUM(number_of_appointments) FILTER (WHERE hypertension = 'yes'))::integer htn_total_appts_scheduled,

       (SUM(number_of_appointments) FILTER (WHERE bucket = 1 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_0_to_14_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 2 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_15_to_31_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 3 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_32_to_62_days,
       (SUM(number_of_appointments) FILTER (WHERE bucket = 4 AND diabetes = 'yes'))::integer AS diabetes_appts_scheduled_more_than_62_days,
       (SUM(number_of_appointments) FILTER (WHERE diabetes = 'yes'))::integer diabetes_total_appts_scheduled
FROM scheduled_days_distribution
GROUP BY facility_id, month_date