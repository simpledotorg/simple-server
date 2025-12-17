SELECT p.id AS patient_id,
  p.month_date,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Amlodipine'::text)), (0)::double precision) AS amlodipine,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Telmisartan'::text)), (0)::double precision) AS telmisartan,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Losartan Potassium'::text)), (0)::double precision) AS losartan,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Atenolol'::text)), (0)::double precision) AS atenolol,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Enalapril'::text)), (0)::double precision) AS enalapril,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Chlorthalidone'::text)), (0)::double precision) AS chlorthalidone,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE ((prescriptions.clean_name)::text = 'Hydrochlorothiazide'::text)), (0)::double precision) AS hydrochlorothiazide,
  COALESCE(max(prescriptions.clean_dosage) FILTER (WHERE (((prescriptions.clean_name)::text <> ALL (ARRAY[('Amlodipine'::character varying)::text, ('Telmisartan'::character varying)::text, ('Losartan'::character varying)::text, ('Atenolol'::character varying)::text, ('Enalapril'::character varying)::text, ('Chlorthalidone'::character varying)::text, ('Hydrochlorothiazide'::character varying)::text])) AND (prescriptions.medicine_purpose_hypertension = true))), (0)::double precision) AS other_bp_medications
FROM (( SELECT p_1.id,
          p_1.full_name,
          p_1.age,
          p_1.gender,
          p_1.date_of_birth,
          p_1.status,
          p_1.created_at,
          p_1.updated_at,
          p_1.address_id,
          p_1.age_updated_at,
          p_1.device_created_at,
          p_1.device_updated_at,
          p_1.test_data,
          p_1.registration_facility_id,
          p_1.registration_user_id,
          p_1.deleted_at,
          p_1.contacted_by_counsellor,
          p_1.could_not_contact_reason,
          p_1.recorded_at,
          p_1.reminder_consent,
          p_1.deleted_by_user_id,
          p_1.deleted_reason,
          p_1.assigned_facility_id,
          cal.month_date,
          cal.month,
          cal.quarter,
          cal.year,
          cal.month_string,
          cal.quarter_string
        FROM (public.patients p_1
          LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.diagnosed_confirmed_at)), 'YYYY-MM'::text) <= cal.month_string)))
        WHERE (p_1.deleted_at IS NULL AND p_1.diagnosed_confirmed_at IS NOT NULL)) p
      LEFT JOIN LATERAL ( SELECT DISTINCT ON (clean.medicine) actual.name AS actual_name,
              actual.dosage AS actual_dosage,
              clean.medicine AS clean_name,
              clean.dosage AS clean_dosage,
              purpose.hypertension AS medicine_purpose_hypertension,
              purpose.diabetes AS medicine_purpose_diabetes
            FROM (((public.prescription_drugs actual
              LEFT JOIN public.raw_to_clean_medicines raw ON (((lower(regexp_replace((raw.raw_name)::text, '\s+'::text, ''::text, 'g'::text)) = lower(regexp_replace((actual.name)::text, '\s+'::text, ''::text, 'g'::text))) AND (lower(regexp_replace((raw.raw_dosage)::text, '\s+'::text, ''::text, 'g'::text)) = lower(regexp_replace((actual.dosage)::text, '\s+'::text, ''::text, 'g'::text))))))
              LEFT JOIN public.clean_medicine_to_dosages clean ON ((clean.rxcui = raw.rxcui)))
              LEFT JOIN public.medicine_purposes purpose ON (((clean.medicine)::text = (purpose.name)::text)))
            WHERE ((actual.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, actual.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (actual.deleted_at IS NULL) AND ((actual.is_deleted = false) OR ((actual.is_deleted = true) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, actual.device_updated_at)), 'YYYY-MM'::text) > p.month_string))))
            ORDER BY clean.medicine, actual.device_created_at DESC) prescriptions ON (true))
    GROUP BY p.id, p.month_date