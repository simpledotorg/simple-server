class UpdateBloodPressuresPerFacilityPerDaysToVersion3 < ActiveRecord::Migration[6.1]
  def up
    drop_view :blood_pressures_per_facility_per_days, materialized: true
    execute <<~SQL
    CREATE MATERIALIZED VIEW public.blood_pressures_per_facility_per_days AS
      WITH registered_patients AS (
          SELECT DISTINCT id
          FROM public.patients
          WHERE deleted_at IS NULL
          AND diagnosed_confirmed_at IS NOT NULL
      ),
      latest_bp_per_patient_per_day AS (
          SELECT DISTINCT ON (blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
          blood_pressures.facility_id,
          (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
          (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
          (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
          (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
          FROM (public.blood_pressures
              JOIN public.medical_histories ON (((blood_pressures.patient_id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text)))
              JOIN registered_patients ON registered_patients.id = blood_pressures.patient_id
          )
          WHERE (blood_pressures.deleted_at IS NULL)
          ORDER BY blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
      )
      SELECT count(latest_bp_per_patient_per_day.bp_id) AS bp_count,
          facilities.id AS facility_id,
          timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
          latest_bp_per_patient_per_day.day,
          latest_bp_per_patient_per_day.month,
          latest_bp_per_patient_per_day.quarter,
          latest_bp_per_patient_per_day.year
        FROM (latest_bp_per_patient_per_day
          JOIN public.facilities ON ((facilities.id = latest_bp_per_patient_per_day.facility_id)))
        GROUP BY latest_bp_per_patient_per_day.day, latest_bp_per_patient_per_day.month, latest_bp_per_patient_per_day.quarter, latest_bp_per_patient_per_day.year, facilities.deleted_at, facilities.id
        WITH NO DATA;
    SQL

    add_index "blood_pressures_per_facility_per_days", ["facility_id", "day", "year"], name: "index_blood_pressures_per_facility_per_days", unique: true
  end

  def down
    drop_view :blood_pressures_per_facility_per_days, materialized: true
    execute <<~SQL
      CREATE MATERIALIZED VIEW public.blood_pressures_per_facility_per_days AS
      WITH latest_bp_per_patient_per_day AS (
        SELECT DISTINCT ON (blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text) blood_pressures.id AS bp_id,
            blood_pressures.facility_id,
            (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS day,
            (date_part('month'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS month,
            (date_part('quarter'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS quarter,
            (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text AS year
          FROM (public.blood_pressures
            JOIN public.medical_histories ON (((blood_pressures.patient_id = medical_histories.patient_id) AND (medical_histories.hypertension = 'yes'::text))))
          WHERE (blood_pressures.deleted_at IS NULL)
          ORDER BY blood_pressures.facility_id, blood_pressures.patient_id, (date_part('year'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, (date_part('doy'::text, timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, blood_pressures.recorded_at))))::text, blood_pressures.recorded_at DESC, blood_pressures.id
      )
      SELECT count(latest_bp_per_patient_per_day.bp_id) AS bp_count,
        facilities.id AS facility_id,
        timezone(( SELECT current_setting('TIMEZONE'::text) AS current_setting), timezone('utc'::text, facilities.deleted_at)) AS deleted_at,
        latest_bp_per_patient_per_day.day,
        latest_bp_per_patient_per_day.month,
        latest_bp_per_patient_per_day.quarter,
        latest_bp_per_patient_per_day.year
      FROM (latest_bp_per_patient_per_day
        JOIN public.facilities ON ((facilities.id = latest_bp_per_patient_per_day.facility_id)))
      GROUP BY latest_bp_per_patient_per_day.day, latest_bp_per_patient_per_day.month, latest_bp_per_patient_per_day.quarter, latest_bp_per_patient_per_day.year, facilities.deleted_at, facilities.id
      WITH NO DATA;
    SQL

    add_index "blood_pressures_per_facility_per_days", ["facility_id", "day", "year"], name: "index_blood_pressures_per_facility_per_days", unique: true
  end
end
