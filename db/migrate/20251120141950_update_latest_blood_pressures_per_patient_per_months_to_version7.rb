class UpdateLatestBloodPressuresPerPatientPerMonthsToVersion7 < ActiveRecord::Migration[6.1]
  def up
    drop_view :latest_blood_pressures_per_patient_per_quarters, materialized: true
    drop_view :latest_blood_pressures_per_patients, materialized: true
    drop_view :latest_blood_pressures_per_patient_per_months, materialized: true

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_months AS
      WITH registered_patients AS (
      SELECT DISTINCT id,
          registration_facility_id,
          assigned_facility_id,
          status,
          recorded_at
      FROM patients
      WHERE deleted_at IS NULL
      AND diagnosed_confirmed_at IS NOT NULL
      )
      SELECT DISTINCT ON (patient_id, year, month)
        blood_pressures.id AS bp_id,
        blood_pressures.patient_id AS patient_id,
        registered_patients.registration_facility_id AS registration_facility_id,
        registered_patients.assigned_facility_id AS assigned_facility_id,
        registered_patients.status as patient_status,
        blood_pressures.facility_id AS bp_facility_id,
        blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS bp_recorded_at,
        registered_patients.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_recorded_at,
        blood_pressures.systolic AS systolic,
        blood_pressures.diastolic AS diastolic,
        blood_pressures.deleted_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS deleted_at,
        medical_histories.hypertension as medical_history_hypertension,
        cast(EXTRACT(MONTH FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS month,
        cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
        cast(EXTRACT(YEAR FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS year
      FROM blood_pressures JOIN registered_patients ON registered_patients.id = blood_pressures.patient_id
        LEFT JOIN medical_histories ON medical_histories.patient_id = blood_pressures.patient_id
        WHERE blood_pressures.deleted_at IS NULL
        ORDER BY patient_id, year, month, blood_pressures.recorded_at DESC, bp_id
        WITH NO DATA;
    SQL

    add_index "latest_blood_pressures_per_patient_per_months", ["assigned_facility_id"], name: "index_bp_months_assigned_facility_id"
    add_index "latest_blood_pressures_per_patient_per_months", ["bp_recorded_at"], name: "index_bp_months_bp_recorded_at"
    add_index "latest_blood_pressures_per_patient_per_months", ["patient_recorded_at"], name: "index_bp_months_patient_recorded_at"
    add_index "latest_blood_pressures_per_patient_per_months", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_months", unique: true
    add_index "latest_blood_pressures_per_patient_per_months", ["patient_id"], name: "index_latest_bp_per_patient_per_months_patient_id"

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_quarters AS
        SELECT DISTINCT ON (patient_id, year, quarter) *
        FROM latest_blood_pressures_per_patient_per_months
        ORDER BY patient_id, year, quarter, bp_recorded_at DESC, bp_id
      WITH NO DATA;
    SQL
    add_index "latest_blood_pressures_per_patient_per_quarters", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_quarters", unique: true
    add_index "latest_blood_pressures_per_patient_per_quarters", ["patient_id"], name: "index_latest_bp_per_patient_per_quarters_patient_id"

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patients AS
        SELECT DISTINCT ON (patient_id) *
        FROM latest_blood_pressures_per_patient_per_months
        ORDER BY patient_id, bp_recorded_at DESC, bp_id
      WITH NO DATA;
    SQL
    add_index "latest_blood_pressures_per_patients", ["bp_id"], name: "index_latest_blood_pressures_per_patients", unique: true
  end

  def down
    drop_view :latest_blood_pressures_per_patient_per_quarters, materialized: true
    drop_view :latest_blood_pressures_per_patients, materialized: true
    drop_view :latest_blood_pressures_per_patient_per_months, materialized: true

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_months AS
        SELECT DISTINCT ON (patient_id, year, month)
          blood_pressures.id AS bp_id,
          blood_pressures.patient_id AS patient_id,
          patients.registration_facility_id AS registration_facility_id,
          patients.assigned_facility_id AS assigned_facility_id,
          patients.status as patient_status,
          blood_pressures.facility_id AS bp_facility_id,
          blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS bp_recorded_at,
          patients.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS patient_recorded_at,
          blood_pressures.systolic AS systolic,
          blood_pressures.diastolic AS diastolic,
          blood_pressures.deleted_at AT TIME ZONE 'UTC' AT TIME ZONE 'UTC' AS deleted_at,
          medical_histories.hypertension as medical_history_hypertension,
          cast(EXTRACT(MONTH FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS month,
          cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
          cast(EXTRACT(YEAR FROM blood_pressures.recorded_at AT TIME ZONE 'UTC' AT TIME ZONE (SELECT current_setting('TIMEZONE'))) as text) AS year
        FROM blood_pressures JOIN patients ON patients.id = blood_pressures.patient_id
        LEFT JOIN medical_histories ON medical_histories.patient_id = blood_pressures.patient_id
        WHERE blood_pressures.deleted_at IS NULL AND patients.deleted_at IS NULL
        ORDER BY patient_id, year, month, blood_pressures.recorded_at DESC, bp_id
        WITH NO DATA;
    SQL
    add_index "latest_blood_pressures_per_patient_per_months", ["assigned_facility_id"], name: "index_bp_months_assigned_facility_id"
    add_index "latest_blood_pressures_per_patient_per_months", ["bp_recorded_at"], name: "index_bp_months_bp_recorded_at"
    add_index "latest_blood_pressures_per_patient_per_months", ["patient_recorded_at"], name: "index_bp_months_patient_recorded_at"
    add_index "latest_blood_pressures_per_patient_per_months", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_months", unique: true
    add_index "latest_blood_pressures_per_patient_per_months", ["patient_id"], name: "index_latest_bp_per_patient_per_months_patient_id"

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patient_per_quarters AS
        SELECT DISTINCT ON (patient_id, year, quarter) *
        FROM latest_blood_pressures_per_patient_per_months
        ORDER BY patient_id, year, quarter, bp_recorded_at DESC, bp_id
      WITH NO DATA;
    SQL
    add_index "latest_blood_pressures_per_patient_per_quarters", ["bp_id"], name: "index_latest_blood_pressures_per_patient_per_quarters", unique: true
    add_index "latest_blood_pressures_per_patient_per_quarters", ["patient_id"], name: "index_latest_bp_per_patient_per_quarters_patient_id"

    execute <<~SQL
      CREATE MATERIALIZED VIEW public.latest_blood_pressures_per_patients AS
        SELECT DISTINCT ON (patient_id) *
        FROM latest_blood_pressures_per_patient_per_months
        ORDER BY patient_id, bp_recorded_at DESC, bp_id
      WITH NO DATA;
    SQL
    add_index "latest_blood_pressures_per_patients", ["bp_id"], name: "index_latest_blood_pressures_per_patients", unique: true
  end
end
