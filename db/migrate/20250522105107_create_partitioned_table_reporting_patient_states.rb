class CreatePartitionedTableReportingPatientStates < ActiveRecord::Migration[6.1]
  def up
    execute "CREATE SCHEMA IF NOT EXISTS simple_reporting"

    execute <<-SQL
      CREATE TABLE IF NOT EXISTS simple_reporting.reporting_patient_states (
        patient_id uuid,
        recorded_at timestamp without time zone,
        status character varying,
        gender character varying,
        age integer,
        age_updated_at timestamp without time zone,
        date_of_birth date,
        current_age double precision,
        month_date date,
        month double precision,
        quarter double precision,
        year double precision,
        month_string text,
        quarter_string text,
        hypertension text,
        prior_heart_attack text,
        prior_stroke text,
        chronic_kidney_disease text,
        receiving_treatment_for_hypertension text,
        diabetes text,
        assigned_facility_id uuid,
        assigned_facility_size character varying,
        assigned_facility_type character varying,
        assigned_facility_slug character varying,
        assigned_facility_region_id uuid,
        assigned_block_slug character varying,
        assigned_block_region_id uuid,
        assigned_district_slug character varying,
        assigned_district_region_id uuid,
        assigned_state_slug character varying,
        assigned_state_region_id uuid,
        assigned_organization_slug character varying,
        assigned_organization_region_id uuid,
        registration_facility_id uuid,
        registration_facility_size character varying,
        registration_facility_type character varying,
        registration_facility_slug character varying,
        registration_facility_region_id uuid,
        registration_block_slug character varying,
        registration_block_region_id uuid,
        registration_district_slug character varying,
        registration_district_region_id uuid,
        registration_state_slug character varying,
        registration_state_region_id uuid,
        registration_organization_slug character varying,
        registration_organization_region_id uuid,
        blood_pressure_id uuid,
        bp_facility_id uuid,
        bp_recorded_at timestamp without time zone,
        systolic integer,
        diastolic integer,
        blood_sugar_id uuid,
        bs_facility_id uuid,
        bs_recorded_at timestamp without time zone,
        blood_sugar_type character varying,
        blood_sugar_value numeric,
        blood_sugar_risk_state text,
        encounter_id uuid,
        encounter_recorded_at timestamp without time zone,
        prescription_drug_id uuid,
        prescription_drug_recorded_at timestamp without time zone,
        appointment_id uuid,
        appointment_recorded_at timestamp without time zone,
        visited_facility_ids uuid[],
        months_since_registration double precision,
        quarters_since_registration double precision,
        months_since_visit double precision,
        quarters_since_visit double precision,
        months_since_bp double precision,
        quarters_since_bp double precision,
        months_since_bs double precision,
        quarters_since_bs double precision,
        last_bp_state text,
        htn_care_state text,
        htn_treatment_outcome_in_last_3_months text,
        htn_treatment_outcome_in_last_2_months text,
        htn_treatment_outcome_in_quarter text,
        diabetes_treatment_outcome_in_last_3_months text,
        diabetes_treatment_outcome_in_last_2_months text,
        diabetes_treatment_outcome_in_quarter text,
        titrated boolean
      )
      PARTITION BY LIST (month_date);
    SQL

    add_index "simple_reporting.reporting_patient_states", [:month_date, :patient_id], unique: true, name: "patient_states_month_date_patient_id"
    add_index "simple_reporting.reporting_patient_states", :age, name: "index_reporting_patient_states_on_age"
    add_index "simple_reporting.reporting_patient_states", :gender, name: "index_reporting_patient_states_on_gender"
    add_index "simple_reporting.reporting_patient_states", [:gender, :age], name: "index_reporting_patient_states_on_gender_and_age"
    add_index "simple_reporting.reporting_patient_states", :assigned_block_region_id, name: "patient_states_assigned_block"
    add_index "simple_reporting.reporting_patient_states", :assigned_district_region_id, name: "patient_states_assigned_district"
    add_index "simple_reporting.reporting_patient_states", :assigned_facility_region_id, name: "patient_states_assigned_facility"
    add_index "simple_reporting.reporting_patient_states", :assigned_state_region_id, name: "patient_states_assigned_state"
    add_index "simple_reporting.reporting_patient_states", [:hypertension, :htn_care_state, :htn_treatment_outcome_in_last_3_months], name: "patient_states_care_state"
    add_index "simple_reporting.reporting_patient_states", :assigned_facility_id, name: "patient_states_month_date_assigned_facility"
    add_index "simple_reporting.reporting_patient_states", :registration_facility_id, name: "patient_states_registration_facility"
    add_index "simple_reporting.reporting_patient_states", :registration_facility_region_id, name: "patient_states_month_date_registration_facility_region"
    add_index "simple_reporting.reporting_patient_states", :bp_facility_id, name: "reporting_patient_states_bp_facility_id"
    add_index "simple_reporting.reporting_patient_states", :titrated, name: "reporting_patient_states_titrated"

    #Create functions used for getting data into a partition
    execute <<-SQL
      CREATE OR REPLACE FUNCTION simple_reporting.reporting_patient_states_table_function(date)
      RETURNS SETOF simple_reporting.reporting_patient_states
      LANGUAGE plpgsql AS $$
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
          ON p.id = bps.patient_id AND cal.month = bps.month AND cal.year = bps.year

        LEFT OUTER JOIN public.reporting_patient_blood_sugars bss
          ON p.id = bss.patient_id AND cal.month = bss.month AND cal.year = bss.year

        LEFT OUTER JOIN public.reporting_patient_visits visits
          ON p.id = visits.patient_id AND cal.month = visits.month AND cal.year = visits.year

        LEFT OUTER JOIN public.medical_histories mh
          ON p.id = mh.patient_id AND mh.deleted_at IS NULL

        LEFT OUTER JOIN public.reporting_prescriptions current_meds
          ON current_meds.patient_id = p.id AND cal.month_date = current_meds.month_date

        LEFT OUTER JOIN public.reporting_prescriptions past_meds
          ON past_meds.patient_id = p.id AND cal.month_date = past_meds.month_date + INTERVAL '1 month'

        INNER JOIN public.reporting_facilities registration_facility
          ON registration_facility.facility_id = p.registration_facility_id

        INNER JOIN public.reporting_facilities assigned_facility
          ON assigned_facility.facility_id = p.assigned_facility_id

        WHERE p.deleted_at IS NULL;
      END;
      $$;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION IF EXISTS simple_reporting.reporting_patient_states_table_function(DATE);
    SQL
    drop_table "simple_reporting.reporting_patient_states"
    execute "DROP SCHEMA IF EXISTS simple_reporting"
  end
end
