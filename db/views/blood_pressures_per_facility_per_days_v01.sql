SELECT COUNT(blood_pressures) AS bp_count,
       facilities.id AS facility_id,
       facilities.deleted_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE')) AS deleted_at,
       cast(EXTRACT(DOY FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS day,
       cast(EXTRACT(MONTH FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS month,
       cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
       cast(EXTRACT(YEAR FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS year
FROM facilities
LEFT OUTER JOIN blood_pressures ON facilities.id = blood_pressures.facility_id
GROUP BY day, month, quarter, year, facilities.deleted_at, facilities.id;
