class RemoveScreenedPatientsFromReportingPatientStates < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL
      ALTER TABLE simple_reporting.reporting_patient_states ADD COLUMN diagnosed_confirmed_at timestamp without time zone;
    SQL

    execute <<~SQL
      UPDATE simple_reporting.reporting_patient_states SET diagnosed_confirmed_at = recorded_at
      WHERE diagnosed_confirmed_at IS NULL AND recorded_at IS NOT NULL;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION simple_reporting.reporting_patient_states_table_function(date) RETURNS SETOF simple_reporting.reporting_patient_states
        LANGUAGE plpgsql
        AS $_$
          BEGIN
            RETURN QUERY
            SELECT DISTINCT ON (p.id)
            -- Basic patient identifiers
              p.id AS patient_id,
              p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS recorded_at,
              p.status,
              p.gender,
              p.age,
              p.age_updated_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS age_updated_at,
              p.date_of_birth,
              EXTRACT(YEAR FROM COALESCE(
                age(p.date_of_birth),
                make_interval(years => p.age) + age(p.age_updated_at)
              ))::float8 AS current_age,

              -- Calendar
              cal.month_date,
              cal.month,
              cal.quarter,
              cal.year,
              cal.month_string,
              cal.quarter_string,

              -- Medical history
              mh.hypertension,
              mh.prior_heart_attack,
              mh.prior_stroke,
              mh.chronic_kidney_disease,
              mh.receiving_treatment_for_hypertension,
              mh.diabetes,

              -- Assigned facility and regions
              p.assigned_facility_id,
              assigned_facility.facility_size,
              assigned_facility.facility_type,
              assigned_facility.facility_region_slug,
              assigned_facility.facility_region_id,
              assigned_facility.block_slug,
              assigned_facility.block_region_id,
              assigned_facility.district_slug,
              assigned_facility.district_region_id,
              assigned_facility.state_slug,
              assigned_facility.state_region_id,
              assigned_facility.organization_slug,
              assigned_facility.organization_region_id,

              -- Registration facility and regions
              p.registration_facility_id,
              registration_facility.facility_size,
              registration_facility.facility_type,
              registration_facility.facility_region_slug,
              registration_facility.facility_region_id,
              registration_facility.block_slug,
              registration_facility.block_region_id,
              registration_facility.district_slug,
              registration_facility.district_region_id,
              registration_facility.state_slug,
              registration_facility.state_region_id,
              registration_facility.organization_slug,
              registration_facility.organization_region_id,

              -- Visit details
              bps.blood_pressure_id,
              bps.blood_pressure_facility_id AS bp_facility_id,
              bps.blood_pressure_recorded_at AS bp_recorded_at,
              bps.systolic,
              bps.diastolic,

              bss.blood_sugar_id,
              bss.blood_sugar_facility_id AS bs_facility_id,
              bss.blood_sugar_recorded_at AS bs_recorded_at,
              bss.blood_sugar_type,
              bss.blood_sugar_value,
              bss.blood_sugar_risk_state,

              visits.encounter_id,
              visits.encounter_recorded_at,
              visits.prescription_drug_id,
              visits.prescription_drug_recorded_at,
              visits.appointment_id,
              visits.appointment_recorded_at,
              visits.visited_facility_ids,

              -- Relative time calculations
              (cal.year - DATE_PART('year', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
              (cal.month - DATE_PART('month', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
              AS months_since_registration,

              (cal.year - DATE_PART('year', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
              (cal.quarter - DATE_PART('quarter', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
              AS quarters_since_registration,

              visits.months_since_visit,
              visits.quarters_since_visit,
              bps.months_since_bp,
              bps.quarters_since_bp,
              bss.months_since_bs,
              bss.quarters_since_bs,

              -- BP and treatment indicators
              CASE
                WHEN bps.systolic IS NULL OR bps.diastolic IS NULL THEN 'unknown'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS last_bp_state,

              CASE
                WHEN p.status = 'dead' THEN 'dead'
                WHEN (
                  (cal.year - DATE_PART('year', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
                  (cal.month - DATE_PART('month', p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) < 12
                  OR visits.months_since_visit < 12
                ) THEN 'under_care'
                ELSE 'lost_to_follow_up'
              END AS htn_care_state,

              CASE
                WHEN visits.months_since_visit >= 3 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.months_since_bp >= 3 OR bps.months_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_last_3_months,

              CASE
                WHEN visits.months_since_visit >= 2 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.months_since_bp >= 2 OR bps.months_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_last_2_months,

              CASE
                WHEN visits.quarters_since_visit >= 1 OR visits.quarters_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.quarters_since_bp >= 1 OR bps.quarters_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_quarter,

              CASE
                WHEN (visits.months_since_visit >= 3 OR visits.months_since_visit is NULL) THEN 'missed_visit'
                WHEN (bss.months_since_bs >= 3 OR bss.months_since_bs is NULL) THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_3_months,

              CASE
                WHEN visits.months_since_visit >= 2 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bss.months_since_bs >= 2 OR bss.months_since_bs IS NULL THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_2_months,

              CASE
                WHEN visits.quarters_since_visit >= 1 OR visits.quarters_since_visit IS NULL THEN 'missed_visit'
                WHEN bss.quarters_since_bs >= 1 OR bss.quarters_since_bs IS NULL THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_quarter,

              (
                current_meds.amlodipine > past_meds.amlodipine OR
                current_meds.telmisartan > past_meds.telmisartan OR
                current_meds.losartan > past_meds.losartan OR
                current_meds.atenolol > past_meds.atenolol OR
                current_meds.enalapril > past_meds.enalapril OR
                current_meds.chlorthalidone > past_meds.chlorthalidone OR
                current_meds.hydrochlorothiazide > past_meds.hydrochlorothiazide
              ) AS titrated,
              p.diagnosed_confirmed_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS diagnosed_confirmed_at

            FROM public.patients p
            JOIN public.reporting_months cal
              ON cal.month_date = $1
              AND p.diagnosed_confirmed_at <= cal.month_date + INTERVAL '1 month' + INTERVAL '1 day'
              AND ((
                to_char(timezone((SELECT current_setting('TIMEZONE'::text) AS current_setting), TIMEZONE('UTC'::text, p.diagnosed_confirmed_at)), 'YYYY-MM'::text) <=
                to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))
              )

            LEFT OUTER JOIN public.reporting_patient_blood_pressures bps
              ON p.id = bps.patient_id AND cal.month_date = bps.month_date

            LEFT OUTER JOIN public.reporting_patient_blood_sugars bss
              ON p.id = bss.patient_id AND cal.month_date = bss.month_date

            LEFT OUTER JOIN public.reporting_patient_visits visits
              ON p.id = visits.patient_id AND cal.month_date = visits.month_date

            LEFT OUTER JOIN LATERAL (
              SELECT DISTINCT ON (patient_id) *
              FROM public.medical_histories
              WHERE patient_id = p.id AND deleted_at IS NULL
              ORDER BY patient_id, device_updated_at DESC
            ) mh ON true

            LEFT OUTER JOIN public.reporting_prescriptions current_meds
              ON current_meds.patient_id = p.id AND cal.month_date = current_meds.month_date

            LEFT OUTER JOIN public.reporting_prescriptions past_meds
              ON past_meds.patient_id = p.id AND cal.month_date = past_meds.month_date + INTERVAL '1 month'

            INNER JOIN public.reporting_facilities registration_facility
              ON registration_facility.facility_id = p.registration_facility_id

            INNER JOIN public.reporting_facilities assigned_facility
              ON assigned_facility.facility_id = p.assigned_facility_id

            WHERE p.deleted_at IS NULL
            AND p.diagnosed_confirmed_at IS NOT NULL
            ORDER BY p.id;
          END;
          $_$;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE simple_reporting.reporting_patient_states DROP COLUMN diagnosed_confirmed_at;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION simple_reporting.reporting_patient_states_table_function(date) RETURNS SETOF simple_reporting.reporting_patient_states
        LANGUAGE plpgsql
        AS $_$
          BEGIN
            RETURN QUERY
            SELECT DISTINCT ON (p.id)
            -- Basic patient identifiers
              p.id AS patient_id,
              p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS recorded_at,
              p.status,
              p.gender,
              p.age,
              p.age_updated_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS age_updated_at,
              p.date_of_birth,
              EXTRACT(YEAR FROM COALESCE(
                age(p.date_of_birth),
                make_interval(years => p.age) + age(p.age_updated_at)
              ))::float8 AS current_age,

              -- Calendar
              cal.month_date,
              cal.month,
              cal.quarter,
              cal.year,
              cal.month_string,
              cal.quarter_string,

              -- Medical history
              mh.hypertension,
              mh.prior_heart_attack,
              mh.prior_stroke,
              mh.chronic_kidney_disease,
              mh.receiving_treatment_for_hypertension,
              mh.diabetes,

              -- Assigned facility and regions
              p.assigned_facility_id,
              assigned_facility.facility_size,
              assigned_facility.facility_type,
              assigned_facility.facility_region_slug,
              assigned_facility.facility_region_id,
              assigned_facility.block_slug,
              assigned_facility.block_region_id,
              assigned_facility.district_slug,
              assigned_facility.district_region_id,
              assigned_facility.state_slug,
              assigned_facility.state_region_id,
              assigned_facility.organization_slug,
              assigned_facility.organization_region_id,

              -- Registration facility and regions
              p.registration_facility_id,
              registration_facility.facility_size,
              registration_facility.facility_type,
              registration_facility.facility_region_slug,
              registration_facility.facility_region_id,
              registration_facility.block_slug,
              registration_facility.block_region_id,
              registration_facility.district_slug,
              registration_facility.district_region_id,
              registration_facility.state_slug,
              registration_facility.state_region_id,
              registration_facility.organization_slug,
              registration_facility.organization_region_id,

              -- Visit details
              bps.blood_pressure_id,
              bps.blood_pressure_facility_id AS bp_facility_id,
              bps.blood_pressure_recorded_at AS bp_recorded_at,
              bps.systolic,
              bps.diastolic,

              bss.blood_sugar_id,
              bss.blood_sugar_facility_id AS bs_facility_id,
              bss.blood_sugar_recorded_at AS bs_recorded_at,
              bss.blood_sugar_type,
              bss.blood_sugar_value,
              bss.blood_sugar_risk_state,

              visits.encounter_id,
              visits.encounter_recorded_at,
              visits.prescription_drug_id,
              visits.prescription_drug_recorded_at,
              visits.appointment_id,
              visits.appointment_recorded_at,
              visits.visited_facility_ids,

              -- Relative time calculations
              (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
              (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
              AS months_since_registration,

              (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 4 +
              (cal.quarter - DATE_PART('quarter', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))))
              AS quarters_since_registration,

              visits.months_since_visit,
              visits.quarters_since_visit,
              bps.months_since_bp,
              bps.quarters_since_bp,
              bss.months_since_bs,
              bss.quarters_since_bs,

              -- BP and treatment indicators
              CASE
                WHEN bps.systolic IS NULL OR bps.diastolic IS NULL THEN 'unknown'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS last_bp_state,

              CASE
                WHEN p.status = 'dead' THEN 'dead'
                WHEN (
                  (cal.year - DATE_PART('year', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) * 12 +
                  (cal.month - DATE_PART('month', p.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE')))) < 12
                  OR visits.months_since_visit < 12
                ) THEN 'under_care'
                ELSE 'lost_to_follow_up'
              END AS htn_care_state,

              CASE
                WHEN visits.months_since_visit >= 3 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.months_since_bp >= 3 OR bps.months_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_last_3_months,

              CASE
                WHEN visits.months_since_visit >= 2 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.months_since_bp >= 2 OR bps.months_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_last_2_months,

              CASE
                WHEN visits.quarters_since_visit >= 1 OR visits.quarters_since_visit IS NULL THEN 'missed_visit'
                WHEN bps.quarters_since_bp >= 1 OR bps.quarters_since_bp IS NULL THEN 'visited_no_bp'
                WHEN bps.systolic < 140 AND bps.diastolic < 90 THEN 'controlled'
                ELSE 'uncontrolled'
              END AS htn_treatment_outcome_in_quarter,

              CASE
                WHEN (visits.months_since_visit >= 3 OR visits.months_since_visit is NULL) THEN 'missed_visit'
                WHEN (bss.months_since_bs >= 3 OR bss.months_since_bs is NULL) THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_3_months,

              CASE
                WHEN visits.months_since_visit >= 2 OR visits.months_since_visit IS NULL THEN 'missed_visit'
                WHEN bss.months_since_bs >= 2 OR bss.months_since_bs IS NULL THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_last_2_months,

              CASE
                WHEN visits.quarters_since_visit >= 1 OR visits.quarters_since_visit IS NULL THEN 'missed_visit'
                WHEN bss.quarters_since_bs >= 1 OR bss.quarters_since_bs IS NULL THEN 'visited_no_bs'
                ELSE bss.blood_sugar_risk_state
              END AS diabetes_treatment_outcome_in_quarter,

              (
                current_meds.amlodipine > past_meds.amlodipine OR
                current_meds.telmisartan > past_meds.telmisartan OR
                current_meds.losartan > past_meds.losartan OR
                current_meds.atenolol > past_meds.atenolol OR
                current_meds.enalapril > past_meds.enalapril OR
                current_meds.chlorthalidone > past_meds.chlorthalidone OR
                current_meds.hydrochlorothiazide > past_meds.hydrochlorothiazide
              ) AS titrated

            FROM public.patients p
            JOIN public.reporting_months cal
              ON cal.month_date = $1
              AND p.recorded_at <= cal.month_date + INTERVAL '1 month' + INTERVAL '1 day'
              AND ((
                to_char(timezone((SELECT current_setting('TIMEZONE'::text) AS current_setting), TIMEZONE('UTC'::text, p.recorded_at)), 'YYYY-MM'::text) <=
                to_char((cal.month_date)::timestamp with time zone, 'YYYY-MM'::text))
              )

            LEFT OUTER JOIN public.reporting_patient_blood_pressures bps
              ON p.id = bps.patient_id AND cal.month_date = bps.month_date

            LEFT OUTER JOIN public.reporting_patient_blood_sugars bss
              ON p.id = bss.patient_id AND cal.month_date = bss.month_date

            LEFT OUTER JOIN public.reporting_patient_visits visits
              ON p.id = visits.patient_id AND cal.month_date = visits.month_date

            LEFT OUTER JOIN LATERAL (
              SELECT DISTINCT ON (patient_id) *
              FROM public.medical_histories
              WHERE patient_id = p.id AND deleted_at IS NULL
              ORDER BY patient_id, device_updated_at DESC
            ) mh ON true

            LEFT OUTER JOIN public.reporting_prescriptions current_meds
              ON current_meds.patient_id = p.id AND cal.month_date = current_meds.month_date

            LEFT OUTER JOIN public.reporting_prescriptions past_meds
              ON past_meds.patient_id = p.id AND cal.month_date = past_meds.month_date + INTERVAL '1 month'

            INNER JOIN public.reporting_facilities registration_facility
              ON registration_facility.facility_id = p.registration_facility_id

            INNER JOIN public.reporting_facilities assigned_facility
              ON assigned_facility.facility_id = p.assigned_facility_id

            WHERE p.deleted_at IS NULL
            ORDER BY p.id;
          END;
          $_$;
    SQL
  end
end
