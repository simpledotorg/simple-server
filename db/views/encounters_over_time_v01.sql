SELECT
  DISTINCT ON (encounters.patient_id, calendar_months.month_date) -- Only most recent Encounter per patient per month. Encounters are ordered appropriately below.
  calendar_months.month_date,
  calendar_months.month,
  calendar_months.quarter,
  calendar_months.year,
  encounters.encountered_on AS encountered_at,
  patients.recorded_at AS patient_registered_at,
  encounters.id AS encounter_id,
  encounters.patient_id,
  patients.assigned_facility_id AS patient_assigned_facility_id,
  patients.registration_facility_id AS patient_registration_facility_id,
  encounters.facility_id AS encounter_facility_id,

  (DATE_PART('year', calendar_months.month_date) - DATE_PART('year', patients.recorded_at)) * 12 +
  (DATE_PART('month', calendar_months.month_date) - DATE_PART('month', patients.recorded_at))
    AS months_since_registration,

  (DATE_PART('year', calendar_months.month_date) - DATE_PART('year', encounters.encountered_on)) * 12 +
  (DATE_PART('month', calendar_months.month_date) - DATE_PART('month', encounters.encountered_on))
    AS months_since_encounter

FROM encounters

LEFT OUTER JOIN calendar_months
  ON (
    -- Only fetch Encounters that happened on or before the selected calendar month
    -- We use year and month comparisons to avoid timezone errors
    EXTRACT(YEAR FROM encounters.encountered_on at time zone 'utc' at time zone 'Asia/Kolkata') < calendar_months.year
    OR
    (
      EXTRACT(YEAR FROM encounters.encountered_on at time zone 'utc' at time zone 'Asia/Kolkata') = calendar_months.year
      AND
      EXTRACT(MONTH FROM encounters.encountered_on at time zone 'utc' at time zone 'Asia/Kolkata') <= calendar_months.month
    )
  )

INNER JOIN patients
  ON encounters.patient_id = patients.id

ORDER BY
  encounters.patient_id,
  calendar_months.month_date,
  encounters.encountered_on DESC -- Ensure most recent Encounter is fetched
