class CreateReportingPatientPrescriptions < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS simple_reporting.reporting_patient_prescriptions (
        patient_id uuid,
        month_date date,
        age integer,
        gender character varying,
        hypertension text,
        diabetes text,
        last_bp_state text,
        htn_care_state text,
        months_since_bp double precision,
        assigned_facility_id uuid,
        assigned_facility_name character varying,
        assigned_facility_size character varying,
        assigned_facility_type character varying,
        assigned_facility_slug character varying,
        assigned_facility_region_id uuid,
        assigned_block_slug character varying,
        assigned_block_region_id uuid,
        assigned_block_name character varying,
        assigned_district_slug character varying,
        assigned_district_region_id uuid,
        assigned_district_name character varying,
        assigned_state_slug character varying,
        assigned_state_region_id uuid,
        assigned_state_name character varying,
        assigned_organization_slug character varying,
        assigned_organization_region_id uuid,
        assigned_organization_name character varying,
        registration_facility_id uuid,
        registration_facility_name character varying,
        registration_facility_size character varying,
        registration_facility_type character varying,
        registration_facility_slug character varying,
        registration_facility_region_id uuid,
        registration_block_slug character varying,
        registration_block_region_id uuid,
        registration_block_name character varying,
        registration_district_slug character varying,
        registration_district_region_id uuid,
        registration_district_name character varying,
        registration_state_slug character varying,
        registration_state_region_id uuid,
        registration_state_name character varying,
        registration_organization_slug character varying,
        registration_organization_region_id uuid,
        registration_organization_name character varying,
        hypertension_prescriptions jsonb,
        diabetes_prescriptions jsonb,
        other_prescriptions jsonb,
        previous_hypertension_prescriptions jsonb,
        previous_diabetes_prescriptions jsonb,
        previous_other_prescriptions jsonb,
        hypertension_drug_changed boolean,
        diabetes_drug_changed boolean,
        other_drug_changed boolean,
        prescribed_statins boolean
      )
      PARTITION BY LIST (month_date);
    SQL

    execute <<~SQL
      CREATE INDEX index_reporting_patient_prescriptions_on_age ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (age);
      CREATE INDEX patient_prescriptions_assigned_facility_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_facility_id);
      CREATE INDEX patient_prescriptions_assigned_facility_region_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_facility_region_id);
      CREATE INDEX patient_prescriptions_assigned_block_region_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_block_region_id);
      CREATE INDEX patient_prescriptions_assigned_district_region_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_district_region_id);
      CREATE INDEX patient_prescriptions_assigned_state_region_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_state_region_id);
      CREATE INDEX patient_prescriptions_assigned_organization_region_id ON ONLY simple_reporting.reporting_patient_prescriptions USING btree (assigned_organization_region_id);
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION simple_reporting.normalize_jsonb_array(input jsonb)
      RETURNS jsonb
      LANGUAGE sql
      IMMUTABLE
      AS $$
        SELECT
          CASE
            WHEN input IS NULL THEN NULL
            ELSE (
              SELECT jsonb_agg(elem ORDER BY elem)
              FROM jsonb_array_elements(input) elem
            )
          END;
      $$;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION simple_reporting.reporting_patient_prescriptions_table_function(date) RETURNS SETOF simple_reporting.reporting_patient_prescriptions
      LANGUAGE plpgsql
      AS $_$
      BEGIN
        RETURN QUERY
        SELECT
          rps.patient_id,
          rps.month_date,
          rps.age,
          rps.gender,
          rps.hypertension,
          rps.diabetes,
          rps.last_bp_state,
          rps.htn_care_state,
          rps.months_since_bp,
          rps.assigned_facility_id,
          assigned_facility.facility_name AS assigned_facility_name,
          rps.assigned_facility_size,
          rps.assigned_facility_type,
          rps.assigned_facility_slug,
          rps.assigned_facility_region_id,
          rps.assigned_block_slug,
          rps.assigned_block_region_id,
          assigned_facility.block_name AS assigned_block_name,
          rps.assigned_district_slug,
          rps.assigned_district_region_id,
          assigned_facility.district_name AS assigned_district_name,
          rps.assigned_state_slug,
          rps.assigned_state_region_id,
          assigned_facility.state_name AS assigned_state_name,
          rps.assigned_organization_slug,
          rps.assigned_organization_region_id,
          assigned_facility.organization_name AS assigned_organization_name,
          rps.registration_facility_id,
          registration_facility.facility_name AS registration_facility_name,
          rps.registration_facility_size,
          rps.registration_facility_type,
          rps.registration_facility_slug,
          rps.registration_facility_region_id,
          rps.registration_block_slug,
          rps.registration_block_region_id,
          registration_facility.block_name AS registration_block_name,
          rps.registration_district_slug,
          rps.registration_district_region_id,
          registration_facility.district_name AS registration_district_name,
          rps.registration_state_slug,
          rps.registration_state_region_id,
          registration_facility.state_name AS registration_state_name,
          rps.registration_organization_slug,
          rps.registration_organization_region_id,
          registration_facility.organization_name AS registration_organization_name,

          curr.hypertension_prescriptions,
          curr.diabetes_prescriptions,
          curr.other_prescriptions,

          prev.hypertension_prescriptions AS previous_hypertension_prescriptions,
          prev.diabetes_prescriptions     AS previous_diabetes_prescriptions,
          prev.other_prescriptions        AS previous_other_prescriptions,

          (
            simple_reporting.normalize_jsonb_array(curr.hypertension_prescriptions)
            IS DISTINCT FROM
            simple_reporting.normalize_jsonb_array(prev.hypertension_prescriptions)
          ) AS hypertension_drug_changed,

          (
            simple_reporting.normalize_jsonb_array(curr.diabetes_prescriptions)
            IS DISTINCT FROM
            simple_reporting.normalize_jsonb_array(prev.diabetes_prescriptions)
          ) AS diabetes_drug_changed,

          (
            simple_reporting.normalize_jsonb_array(curr.other_prescriptions)
            IS DISTINCT FROM
            simple_reporting.normalize_jsonb_array(prev.other_prescriptions)
          ) AS other_drug_changed,

          (
            EXISTS (
              SELECT 1
              FROM jsonb_array_elements(
                COALESCE(curr.hypertension_prescriptions, '[]'::jsonb)
                || COALESCE(curr.diabetes_prescriptions, '[]'::jsonb)
                || COALESCE(curr.other_prescriptions, '[]'::jsonb)
              ) elem
              WHERE elem->>'drug_name' ILIKE '%statin%'
            )
          ) AS prescribed_statins

        FROM simple_reporting.reporting_patient_states rps
        LEFT JOIN reporting_facilities assigned_facility ON rps.assigned_facility_id = assigned_facility.facility_id
        LEFT JOIN reporting_facilities registration_facility ON rps.registration_facility_id = registration_facility.facility_id

        LEFT JOIN LATERAL (
          SELECT
            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (WHERE mp.hypertension = true) AS hypertension_prescriptions,

            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (WHERE mp.diabetes = true) AS diabetes_prescriptions,

            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (
              WHERE
                mp.name IS NULL OR (
                  COALESCE(mp.hypertension,false) = false
                  AND COALESCE(mp.diabetes,false) = false
                )
            ) AS other_prescriptions

          FROM prescription_drugs pd
          LEFT JOIN medicine_purposes mp ON mp.name = pd.name
          WHERE pd.patient_id = rps.patient_id
            AND pd.deleted_at IS NULL
            AND to_char(timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_created_at)),'YYYY-MM') <= to_char(rps.month_date, 'YYYY-MM')
            AND (pd.is_deleted = false
              OR (
                pd.is_deleted = true
                AND to_char(timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_updated_at)), 'YYYY-MM') > to_char(rps.month_date, 'YYYY-MM')
              )
            )
        ) curr ON TRUE

        LEFT JOIN LATERAL (
          SELECT
            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (WHERE mp.hypertension = true) AS hypertension_prescriptions,

            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (WHERE mp.diabetes = true) AS diabetes_prescriptions,

            jsonb_agg(jsonb_build_object(
              'drug_name', pd.name,
              'dosage', pd.dosage
            )) FILTER (
              WHERE
                mp.name IS NULL OR (
                  COALESCE(mp.hypertension,false) = false
                  AND COALESCE(mp.diabetes,false) = false
                )
            ) AS other_prescriptions
          
          FROM prescription_drugs pd
          LEFT JOIN medicine_purposes mp ON mp.name = pd.name
          WHERE pd.patient_id = rps.patient_id
            AND pd.deleted_at IS NULL
            AND to_char(timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_created_at)), 'YYYY-MM') <= to_char(rps.month_date - INTERVAL '1 month', 'YYYY-MM')
            AND ( pd.is_deleted = false
              OR (
                pd.is_deleted = true
                AND to_char(timezone(current_setting('TIMEZONE'), timezone('UTC', pd.device_updated_at)), 'YYYY-MM') > to_char(rps.month_date - INTERVAL '1 month', 'YYYY-MM')
              )
            )
        ) prev ON TRUE
        WHERE rps.month_date = $1
        AND rps.htn_care_state <> 'dead';
      END;
      $_$;
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION IF EXISTS simple_reporting.normalize_jsonb_array(jsonb);
    SQL

    execute <<~SQL
      DROP FUNCTION IF EXISTS simple_reporting.reporting_patient_prescriptions_table_function(date);
    SQL

    drop_table "simple_reporting.reporting_patient_prescriptions"
  end
end
