WITH follow_up_blood_pressures AS (
    SELECT DISTINCT ON (p.id, bp.facility_id, bp.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text))) p.id AS patient_id,
    (p.gender)::public.gender_enum AS patient_gender,
    bp.id AS visit_id,
    'BloodPressure'::text AS visit_type,
    bp.facility_id,
    bp.user_id,
    bp.recorded_at AS visited_at,
    to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at)), 'YYYY-MM'::text) AS month_string
    FROM (public.patients p
        JOIN public.blood_pressures bp ON (((p.id = bp.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bp.recorded_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))))))
    WHERE (p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL)
), follow_up_blood_sugars AS (
    SELECT DISTINCT ON (p.id, bs.facility_id, bs.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)), 'YYYY-MM'::text))) p.id AS patient_id,
    (p.gender)::public.gender_enum AS patient_gender,
    bs.id AS visit_id,
    'BloodSugar'::text AS visit_type,
    bs.facility_id,
    bs.user_id,
    bs.recorded_at AS visited_at,
    to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at)), 'YYYY-MM'::text) AS month_string
    FROM (public.patients p
        JOIN public.blood_sugars bs ON (((p.id = bs.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, bs.recorded_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))))))
    WHERE (p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL)
), follow_up_prescription_drugs AS (
    SELECT DISTINCT ON (p.id, pd.facility_id, pd.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at)), 'YYYY-MM'::text))) p.id AS patient_id,
    (p.gender)::public.gender_enum AS patient_gender,
    pd.id AS visit_id,
    'PrescriptionDrug'::text AS visit_type,
    pd.facility_id,
    pd.user_id,
    pd.device_created_at AS visited_at,
    to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at)), 'YYYY-MM'::text) AS month_string
    FROM (public.patients p
        JOIN public.prescription_drugs pd ON (((p.id = pd.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, pd.device_created_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))))))
    WHERE (p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL)
), follow_up_appointments AS (
    SELECT DISTINCT ON (p.id, app.creation_facility_id, app.user_id, (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at)), 'YYYY-MM'::text))) p.id AS patient_id,
    (p.gender)::public.gender_enum AS patient_gender,
    app.id AS visit_id,
    'Appointment'::text AS visit_type,
    app.creation_facility_id AS facility_id,
    app.user_id,
    app.device_created_at AS visited_at,
    to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at)), 'YYYY-MM'::text) AS month_string
    FROM (public.patients p
        JOIN public.appointments app ON (((p.id = app.patient_id) AND (date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, app.device_created_at))) > date_trunc('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, p.diagnosed_confirmed_at)))))))
    WHERE (p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL)
), all_follow_ups AS (
    SELECT follow_up_blood_pressures.patient_id,
    follow_up_blood_pressures.patient_gender,
    follow_up_blood_pressures.visit_id,
    follow_up_blood_pressures.visit_type,
    follow_up_blood_pressures.facility_id,
    follow_up_blood_pressures.user_id,
    follow_up_blood_pressures.visited_at,
    follow_up_blood_pressures.month_string
    FROM follow_up_blood_pressures
UNION
    SELECT follow_up_blood_sugars.patient_id,
    follow_up_blood_sugars.patient_gender,
    follow_up_blood_sugars.visit_id,
    follow_up_blood_sugars.visit_type,
    follow_up_blood_sugars.facility_id,
    follow_up_blood_sugars.user_id,
    follow_up_blood_sugars.visited_at,
    follow_up_blood_sugars.month_string
    FROM follow_up_blood_sugars
UNION
    SELECT follow_up_prescription_drugs.patient_id,
    follow_up_prescription_drugs.patient_gender,
    follow_up_prescription_drugs.visit_id,
    follow_up_prescription_drugs.visit_type,
    follow_up_prescription_drugs.facility_id,
    follow_up_prescription_drugs.user_id,
    follow_up_prescription_drugs.visited_at,
    follow_up_prescription_drugs.month_string
    FROM follow_up_prescription_drugs
UNION
    SELECT follow_up_appointments.patient_id,
    follow_up_appointments.patient_gender,
    follow_up_appointments.visit_id,
    follow_up_appointments.visit_type,
    follow_up_appointments.facility_id,
    follow_up_appointments.user_id,
    follow_up_appointments.visited_at,
    follow_up_appointments.month_string
    FROM follow_up_appointments
)
SELECT DISTINCT ON (cal.month_string, all_follow_ups.facility_id, all_follow_ups.user_id, all_follow_ups.patient_id) all_follow_ups.patient_id,
    all_follow_ups.patient_gender,
    all_follow_ups.facility_id,
    mh.diabetes,
    mh.hypertension,
    all_follow_ups.user_id,
    all_follow_ups.visit_id,
    all_follow_ups.visit_type,
    all_follow_ups.visited_at,
    cal.month_date,
    cal.month,
    cal.quarter,
    cal.year,
    cal.month_string,
    cal.quarter_string
FROM ((all_follow_ups
    JOIN public.medical_histories mh ON ((all_follow_ups.patient_id = mh.patient_id)))
    LEFT JOIN public.reporting_months cal ON ((all_follow_ups.month_string = cal.month_string)))
ORDER BY cal.month_string DESC;