SELECT p.id as patient_id,
       p.month_date,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Amlodipine'), 0)          as amlodipine,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Telmisartan'), 0)         as telmisartan,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Losartan Potassium'), 0)  as losartan,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Atenolol'), 0)            as atenolol,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Enalapril'), 0)           as enalapril,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Chlorthalidone'), 0)      as chlorthalidone,
       COALESCE(max(clean_dosage) FILTER (WHERE clean_name = 'Hydrochlorothiazide'), 0) as hydrochlorothiazide,
       COALESCE(max(clean_dosage)
           FILTER (
              WHERE clean_name NOT IN ('Amlodipine', 'Telmisartan', 'Losartan', 'Atenolol', 'Enalapril', 'Chlorthalidone', 'Hydrochlorothiazide')
              AND medicine_purpose_hypertension = true),
           0) as other_bp_medications
FROM (
         SELECT *
         FROM patients p
         LEFT OUTER JOIN reporting_months cal
         ON to_char(p.recorded_at AT TIME ZONE 'utc' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= cal.month_string
         WHERE p.deleted_at is null
     ) p
LEFT JOIN LATERAL (
    SELECT DISTINCT ON (clean.medicine)
           actual.name          as actual_name,
           actual.dosage        as actual_dosage,
           clean.medicine       as clean_name,
           clean.dosage         as clean_dosage,
           purpose.hypertension as medicine_purpose_hypertension,
           purpose.diabetes     as medicine_purpose_diabetes
    FROM prescription_drugs actual
             LEFT JOIN raw_to_clean_medicines raw
                       ON lower(regexp_replace(raw.raw_name, '\s+', '', 'g')) =
                          lower(regexp_replace(actual.name, '\s+', '', 'g'))
                           AND lower(regexp_replace(raw.raw_dosage, '\s+', '', 'g')) =
                               lower(regexp_replace(actual.dosage, '\s+', '', 'g'))
             LEFT JOIN clean_medicine_to_dosages clean
                       ON clean.rxcui = raw.rxcui
             LEFT JOIN medicine_purposes purpose
                       ON clean.medicine = purpose.name
    WHERE patient_id = p.id
      AND to_char(device_created_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') <= p.month_string
      AND deleted_at is null
      AND (is_deleted = false OR (is_deleted = true AND to_char(device_updated_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')), 'YYYY-MM') > p.month_string))
    ORDER BY clean.medicine, actual.device_created_at desc
    ) prescriptions ON true
GROUP BY 1, 2
