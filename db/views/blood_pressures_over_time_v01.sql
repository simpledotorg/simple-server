SELECT
  DISTINCT ON (blood_pressures.patient_id, calendar_months.month_date) -- Only most recent BP per patient per month. BPs are ordered appropriately below.
  calendar_months.month_date,
  calendar_months.month,
  calendar_months.quarter,
  calendar_months.year,
  blood_pressures.recorded_at AS blood_pressure_recorded_at,
  patients.recorded_at AS patient_registered_at,
  blood_pressures.id AS blood_pressure_id,
  blood_pressures.patient_id,
  blood_pressures.systolic,
  blood_pressures.diastolic,
  patients.assigned_facility_id AS patient_assigned_facility_id,
  patients.registration_facility_id AS patient_registration_facility_id,
  blood_pressures.facility_id AS blood_pressure_facility_id,

  (DATE_PART('year', calendar_months.month_date) - DATE_PART('year', patients.recorded_at)) * 12 +
  (DATE_PART('month', calendar_months.month_date) - DATE_PART('month', patients.recorded_at))
    AS months_since_registration,

  (DATE_PART('year', calendar_months.month_date) - DATE_PART('year', blood_pressures.recorded_at)) * 12 +
  (DATE_PART('month', calendar_months.month_date) - DATE_PART('month', blood_pressures.recorded_at))
    AS months_since_bp_observation

FROM blood_pressures
    -- List of months from 2018 to now --
LEFT OUTER JOIN calendar_months
  ON (
    -- Only fetch BPs that happened on or before the selected calendar month
    -- We use year and month comparisons to avoid timezone errors
    EXTRACT(YEAR FROM blood_pressures.recorded_at AT TIME ZONE 'utc' AT TIME ZONE 'Asia/Kolkata') < calendar_months.year
    OR
    (
      EXTRACT(YEAR FROM blood_pressures.recorded_at AT TIME ZONE 'utc' AT TIME ZONE 'Asia/Kolkata') = calendar_months.year
      AND
      EXTRACT(MONTH FROM blood_pressures.recorded_at AT TIME ZONE 'utc' AT TIME ZONE 'Asia/Kolkata') <= calendar_months.month
    )
  )

INNER JOIN patients
  ON blood_pressures.patient_id = patients.id

ORDER BY
  blood_pressures.patient_id,
  calendar_months.month_date,
  blood_pressures.recorded_at DESC -- Ensure most recent BP is fetched
