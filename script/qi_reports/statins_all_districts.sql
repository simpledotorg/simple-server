-- Statins by district, ALL districts at once (for the QI reports page).
-- Same logic as Metabase question 1129; the only change is the last step, which returns every district
-- instead of one selected district. Set the variable from_date (Date) to the first day of the first month
-- you want, e.g. 2026-05-01.

WITH cvd_pairs AS (
  SELECT DISTINCT
    patient_id,
    cvd_risk_score_month AS month_date
  FROM (
    SELECT
      patient_id,
      risk_score,
      date_trunc('month', device_updated_at) :: DATE AS cvd_risk_score_month,
      ROW_NUMBER() OVER (
        PARTITION BY patient_id, date_trunc('month', device_updated_at)
        ORDER BY device_updated_at DESC
      ) AS rn
    FROM cvd_risks
    WHERE deleted_at IS NULL
      AND date_trunc('month', device_updated_at) :: DATE >= {{from_date}}
  ) ranked_risks
  WHERE (
      risk_score ~ '^\d+$'
      AND CAST(TRIM(risk_score) AS INTEGER) >= 10
    )
    OR (
      risk_score ~ '^\d+\s*-\s*\d+$'
      AND CAST(TRIM(split_part(risk_score, '-', 1)) AS INTEGER) >= 10
      AND rn = 1
    )
),

eligible_patients AS MATERIALIZED (
  SELECT
    rps.patient_id,
    rps.month_date,
    rps.assigned_district_slug
  FROM reporting_patient_states rps
    LEFT JOIN cvd_pairs cvd
           ON cvd.patient_id = rps.patient_id
          AND cvd.month_date = rps.month_date
  WHERE rps.month_date >= {{from_date}}
    AND rps.assigned_organization_slug = 'nhf'
    AND rps.htn_care_state = 'under_care'
    AND (
      rps.prior_heart_attack = 'yes'
      OR rps.prior_stroke = 'yes'
      OR (
        rps.diabetes = 'yes'
        AND CASE
              WHEN rps.date_of_birth IS NOT NULL
                THEN DATE_PART('year', AGE(rps.month_date, rps.date_of_birth))
              ELSE DATE_PART(
                     'year',
                     AGE(
                       rps.month_date,
                       (
                         rps.age_updated_at AT TIME ZONE 'UTC' AT TIME ZONE (
                           SELECT CURRENT_SETTING('TIMEZONE')
                         )
                       ) :: DATE
                     )
                   ) + rps.age
            END >= 40
      )
      OR cvd.patient_id IS NOT NULL
    )
),

statin_drugs AS MATERIALIZED (
  SELECT
    pd.patient_id,
    pd.is_deleted,
    pd.device_updated_at,
    (
      pd.device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT CURRENT_SETTING('TIMEZONE')
      )
    ) AS created_local
  FROM prescription_drugs pd
  WHERE pd.name ILIKE '%statin%'
),

statin_first_active AS (
  SELECT
    patient_id,
    MIN(created_local) AS first_created_local
  FROM statin_drugs
  WHERE is_deleted = false
  GROUP BY patient_id
),

statin_deleted AS (
  SELECT patient_id, created_local, device_updated_at
  FROM statin_drugs
  WHERE is_deleted = true
),

statin_pairs AS (
  SELECT
    ep.patient_id,
    ep.month_date
  FROM eligible_patients ep
    JOIN statin_first_active sa
      ON sa.patient_id = ep.patient_id
     AND sa.first_created_local < ep.month_date + INTERVAL '1 month'
  UNION
  SELECT
    ep.patient_id,
    ep.month_date
  FROM eligible_patients ep
    JOIN statin_deleted sd
      ON sd.patient_id = ep.patient_id
     AND sd.created_local < ep.month_date + INTERVAL '1 month'
    JOIN reporting_patient_visits rpv
      ON rpv.patient_id = ep.patient_id
     AND rpv.month_date = ep.month_date
     AND rpv.month_date >= {{from_date}}
  WHERE (
      sd.device_updated_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT CURRENT_SETTING('TIMEZONE')
      )
    ) >= (
      rpv.visited_at AT TIME ZONE 'UTC' AT TIME ZONE (
        SELECT CURRENT_SETTING('TIMEZONE')
      )
    )
),

statin_report AS (
  SELECT
    ep.month_date,
    ep.assigned_district_slug,
    COUNT(ep.patient_id) AS the_eligible_patients,
    COUNT(sp.patient_id) AS statin_patients
  FROM eligible_patients ep
    LEFT JOIN statin_pairs sp
           ON sp.patient_id = ep.patient_id
          AND sp.month_date = ep.month_date
  GROUP BY
    ep.month_date,
    ep.assigned_district_slug
),

source AS (
  SELECT
    month_date,
    assigned_district_slug,
    the_eligible_patients,
    statin_patients,
    (statin_patients * 100.00) / NULLIF(the_eligible_patients, 0) AS percentage_statin_patients
  FROM statin_report
),

all_districts AS (
  SELECT DISTINCT
    district_name,
    district_slug
  FROM reporting_facilities
),

district_report AS (
  SELECT
    month_date,
    all_districts.district_name AS district,
    the_eligible_patients,
    statin_patients,
    (statin_patients * 100.00) / NULLIF(the_eligible_patients, 0) AS percentage_statin_patients
  FROM source
    JOIN all_districts ON source.assigned_district_slug = all_districts.district_slug
),

averages AS (
  SELECT
    month_date,
    'Average' AS district,
    SUM(the_eligible_patients) AS the_eligible_patients,
    SUM(statin_patients) AS statin_patients,
    (SUM(statin_patients) * 100.00) / NULLIF(SUM(the_eligible_patients), 0) AS percentage_statin_patients
  FROM source
  GROUP BY month_date
)

SELECT * FROM district_report
UNION ALL
SELECT * FROM averages
ORDER BY
  month_date,
  district
;
