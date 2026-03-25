class AddCvdRiskScoreToReportingPatientPrescriptions < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      ALTER TABLE simple_reporting.reporting_patient_prescriptions
      ADD COLUMN latest_cvd_risk_score_lower_range integer,
      ADD COLUMN latest_cvd_risk_score_upper_range integer;

      CREATE OR REPLACE VIEW public.reporting_patient_prescriptions AS SELECT * FROM simple_reporting.reporting_patient_prescriptions;
    SQL

    execute <<~SQL
      CREATE INDEX idx_rpp_month_patient ON simple_reporting.reporting_patient_prescriptions (month_date, patient_id);
      CREATE INDEX idx_rpp_latest_cvd_score_lower_range ON simple_reporting.reporting_patient_prescriptions (latest_cvd_risk_score_lower_range);
      CREATE INDEX idx_rpp_latest_cvd_score_upper_range ON simple_reporting.reporting_patient_prescriptions (latest_cvd_risk_score_upper_range);
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
          ) AS prescribed_statins,

          cvd.latest_cvd_risk_score_lower_range,
          cvd.latest_cvd_risk_score_upper_range

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

        LEFT JOIN LATERAL (
          SELECT
            split_part(cr.risk_score,'-',1)::int AS latest_cvd_risk_score_lower_range,

            COALESCE(
              NULLIF(split_part(cr.risk_score,'-',2),''),
              split_part(cr.risk_score,'-',1)
            )::int AS latest_cvd_risk_score_upper_range

          FROM cvd_risks cr
          WHERE cr.patient_id = rps.patient_id
            AND cr.deleted_at IS NULL
            AND date_trunc('month',
                  timezone(current_setting('TIMEZONE'),
                  timezone('UTC', cr.device_updated_at))
                ) < (rps.month_date + interval '1 month')

          ORDER BY cr.device_updated_at DESC
          LIMIT 1
        ) cvd ON TRUE

        WHERE rps.month_date = $1
        AND rps.htn_care_state <> 'dead';
      END;
      $_$;
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS public.reporting_patient_prescriptions;
      ALTER TABLE simple_reporting.reporting_patient_prescriptions
      DROP COLUMN latest_cvd_risk_score_lower_range,
      DROP COLUMN latest_cvd_risk_score_upper_range;

      CREATE OR REPLACE VIEW public.reporting_patient_prescriptions AS SELECT * FROM simple_reporting.reporting_patient_prescriptions;
    SQL

    execute <<~SQL
      DROP INDEX IF EXISTS simple_reporting.idx_rpp_month_patient;
      DROP INDEX IF EXISTS simple_reporting.idx_rpp_latest_cvd_score_lower_range;
      DROP INDEX IF EXISTS simple_reporting.idx_rpp_latest_cvd_score_upper_range;
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
end
