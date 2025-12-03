class UpdateReportingPatientVisitsToVersion4 < ActiveRecord::Migration[6.1]
  def up
    drop_view :reporting_patient_visits, materialized: true
    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_patient_visits AS
        SELECT DISTINCT ON (p.id, p.month_date) p.id AS patient_id,
            p.month_date,
            p.month,
            p.quarter,
            p.year,
            p.month_string,
            p.quarter_string,
            p.assigned_facility_id,
            p.registration_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, p.diagnosed_confirmed_at)) AS patient_recorded_at,
            e.id AS encounter_id,
            e.facility_id AS encounter_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, e.recorded_at)) AS encounter_recorded_at,
            pd.id AS prescription_drug_id,
            pd.facility_id AS prescription_drug_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, pd.recorded_at)) AS prescription_drug_recorded_at,
            app.id AS appointment_id,
            app.creation_facility_id AS appointment_creation_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, app.recorded_at)) AS appointment_recorded_at,
            array_remove(ARRAY[
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, e.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN e.facility_id
                    ELSE NULL::uuid
                END,
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, pd.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN pd.facility_id
                    ELSE NULL::uuid
                END,
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, app.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN app.creation_facility_id
                    ELSE NULL::uuid
                END], NULL::uuid) AS visited_facility_ids,
            timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))) AS visited_at,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.diagnosed_confirmed_at)))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.diagnosed_confirmed_at))))) AS months_since_registration,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.diagnosed_confirmed_at)))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.diagnosed_confirmed_at))))) AS quarters_since_registration,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS months_since_visit,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS quarters_since_visit
          FROM (((( SELECT p_1.id,
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
                    p_1.diagnosed_confirmed_at,
                    cal.month_date,
                    cal.month,
                    cal.quarter,
                    cal.year,
                    cal.month_string,
                    cal.quarter_string
                  FROM (public.patients p_1
                    LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.diagnosed_confirmed_at)), 'YYYY-MM'::text) <= cal.month_string)))) p
            LEFT JOIN LATERAL ( SELECT timezone('UTC'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), (encounters.encountered_on)::timestamp without time zone)) AS recorded_at,
                    encounters.id,
                    encounters.facility_id,
                    encounters.patient_id,
                    encounters.encountered_on,
                    encounters.timezone_offset,
                    encounters.notes,
                    encounters.metadata,
                    encounters.device_created_at,
                    encounters.device_updated_at,
                    encounters.deleted_at,
                    encounters.created_at,
                    encounters.updated_at
                  FROM public.encounters
                  WHERE ((encounters.patient_id = p.id) AND (to_char((encounters.encountered_on)::timestamp with time zone, 'YYYY-MM'::text) <= p.month_string) AND (encounters.deleted_at IS NULL))
                  ORDER BY encounters.encountered_on DESC
                LIMIT 1) e ON (true))
            LEFT JOIN LATERAL ( SELECT prescription_drugs.device_created_at AS recorded_at,
                    prescription_drugs.id,
                    prescription_drugs.name,
                    prescription_drugs.rxnorm_code,
                    prescription_drugs.dosage,
                    prescription_drugs.device_created_at,
                    prescription_drugs.device_updated_at,
                    prescription_drugs.created_at,
                    prescription_drugs.updated_at,
                    prescription_drugs.patient_id,
                    prescription_drugs.facility_id,
                    prescription_drugs.is_protocol_drug,
                    prescription_drugs.is_deleted,
                    prescription_drugs.deleted_at,
                    prescription_drugs.user_id,
                    prescription_drugs.frequency,
                    prescription_drugs.duration_in_days,
                    prescription_drugs.teleconsultation_id
                  FROM public.prescription_drugs
                  WHERE ((prescription_drugs.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, prescription_drugs.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (prescription_drugs.deleted_at IS NULL))
                  ORDER BY prescription_drugs.device_created_at DESC
                LIMIT 1) pd ON (true))
            LEFT JOIN LATERAL ( SELECT appointments.device_created_at AS recorded_at,
                    appointments.id,
                    appointments.patient_id,
                    appointments.facility_id,
                    appointments.scheduled_date,
                    appointments.status,
                    appointments.cancel_reason,
                    appointments.device_created_at,
                    appointments.device_updated_at,
                    appointments.created_at,
                    appointments.updated_at,
                    appointments.remind_on,
                    appointments.agreed_to_visit,
                    appointments.deleted_at,
                    appointments.appointment_type,
                    appointments.user_id,
                    appointments.creation_facility_id
                  FROM public.appointments
                  WHERE ((appointments.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, appointments.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (appointments.deleted_at IS NULL))
                  ORDER BY appointments.device_created_at DESC
                LIMIT 1) app ON (true))
          WHERE (p.deleted_at IS NULL AND p.diagnosed_confirmed_at IS NOT NULL)
          ORDER BY p.id, p.month_date, (timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))) DESC
          WITH NO DATA;
    SQL

    add_index "reporting_patient_visits", ["month_date", "patient_id"], name: "patient_visits_patient_id_month_date", unique: true
  end

  def down
    drop_view :reporting_patient_visits, materialized: true
    execute <<~SQL
      CREATE MATERIALIZED VIEW public.reporting_patient_visits AS
        SELECT DISTINCT ON (p.id, p.month_date) p.id AS patient_id,
            p.month_date,
            p.month,
            p.quarter,
            p.year,
            p.month_string,
            p.quarter_string,
            p.assigned_facility_id,
            p.registration_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, p.recorded_at)) AS patient_recorded_at,
            e.id AS encounter_id,
            e.facility_id AS encounter_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, e.recorded_at)) AS encounter_recorded_at,
            pd.id AS prescription_drug_id,
            pd.facility_id AS prescription_drug_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, pd.recorded_at)) AS prescription_drug_recorded_at,
            app.id AS appointment_id,
            app.creation_facility_id AS appointment_creation_facility_id,
            timezone('UTC'::text, timezone('UTC'::text, app.recorded_at)) AS appointment_recorded_at,
            array_remove(ARRAY[
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, e.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN e.facility_id
                    ELSE NULL::uuid
                END,
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, pd.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN pd.facility_id
                    ELSE NULL::uuid
                END,
                CASE
                    WHEN (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, app.recorded_at)), 'YYYY-MM'::text) = p.month_string) THEN app.creation_facility_id
                    ELSE NULL::uuid
                END], NULL::uuid) AS visited_facility_ids,
            timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))) AS visited_at,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS months_since_registration,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at)))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p.recorded_at))))) AS quarters_since_registration,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (12)::double precision) + (p.month - date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS months_since_visit,
            (((p.year - date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at))))) * (4)::double precision) + (p.quarter - date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))))) AS quarters_since_visit
          FROM (((( SELECT p_1.id,
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
                    LEFT JOIN public.reporting_months cal ON ((to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, p_1.recorded_at)), 'YYYY-MM'::text) <= cal.month_string)))) p
            LEFT JOIN LATERAL ( SELECT timezone('UTC'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), (encounters.encountered_on)::timestamp without time zone)) AS recorded_at,
                    encounters.id,
                    encounters.facility_id,
                    encounters.patient_id,
                    encounters.encountered_on,
                    encounters.timezone_offset,
                    encounters.notes,
                    encounters.metadata,
                    encounters.device_created_at,
                    encounters.device_updated_at,
                    encounters.deleted_at,
                    encounters.created_at,
                    encounters.updated_at
                  FROM public.encounters
                  WHERE ((encounters.patient_id = p.id) AND (to_char((encounters.encountered_on)::timestamp with time zone, 'YYYY-MM'::text) <= p.month_string) AND (encounters.deleted_at IS NULL))
                  ORDER BY encounters.encountered_on DESC
                LIMIT 1) e ON (true))
            LEFT JOIN LATERAL ( SELECT prescription_drugs.device_created_at AS recorded_at,
                    prescription_drugs.id,
                    prescription_drugs.name,
                    prescription_drugs.rxnorm_code,
                    prescription_drugs.dosage,
                    prescription_drugs.device_created_at,
                    prescription_drugs.device_updated_at,
                    prescription_drugs.created_at,
                    prescription_drugs.updated_at,
                    prescription_drugs.patient_id,
                    prescription_drugs.facility_id,
                    prescription_drugs.is_protocol_drug,
                    prescription_drugs.is_deleted,
                    prescription_drugs.deleted_at,
                    prescription_drugs.user_id,
                    prescription_drugs.frequency,
                    prescription_drugs.duration_in_days,
                    prescription_drugs.teleconsultation_id
                  FROM public.prescription_drugs
                  WHERE ((prescription_drugs.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, prescription_drugs.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (prescription_drugs.deleted_at IS NULL))
                  ORDER BY prescription_drugs.device_created_at DESC
                LIMIT 1) pd ON (true))
            LEFT JOIN LATERAL ( SELECT appointments.device_created_at AS recorded_at,
                    appointments.id,
                    appointments.patient_id,
                    appointments.facility_id,
                    appointments.scheduled_date,
                    appointments.status,
                    appointments.cancel_reason,
                    appointments.device_created_at,
                    appointments.device_updated_at,
                    appointments.created_at,
                    appointments.updated_at,
                    appointments.remind_on,
                    appointments.agreed_to_visit,
                    appointments.deleted_at,
                    appointments.appointment_type,
                    appointments.user_id,
                    appointments.creation_facility_id
                  FROM public.appointments
                  WHERE ((appointments.patient_id = p.id) AND (to_char(timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('UTC'::text, appointments.device_created_at)), 'YYYY-MM'::text) <= p.month_string) AND (appointments.deleted_at IS NULL))
                  ORDER BY appointments.device_created_at DESC
                LIMIT 1) app ON (true))
          WHERE (p.deleted_at IS NULL)
          ORDER BY p.id, p.month_date, (timezone('UTC'::text, timezone('UTC'::text, GREATEST(e.recorded_at, pd.recorded_at, app.recorded_at)))) DESC
          WITH NO DATA;
    SQL

    add_index "reporting_patient_visits", ["month_date", "patient_id"], name: "patient_visits_patient_id_month_date", unique: true
  end
end
