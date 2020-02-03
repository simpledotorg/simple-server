SELECT COUNT(patients.id) AS registration_count,
       patients.registration_facility_id AS facility_id,
       facilities.deleted_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE')) AS deleted_at,
cast(EXTRACT(DOY FROM patients.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS day,
cast(EXTRACT(MONTH FROM patients.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS month,
cast(EXTRACT(QUARTER FROM patients.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
cast(EXTRACT(YEAR FROM patients.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS year
FROM patients
INNER JOIN facilities ON patients.registration_facility_id = facilities.id
WHERE patients.deleted_at IS NULL
GROUP BY day, month, quarter, year, facility_id, facilities.deleted_at;
