class CreateBloodPressureRollups < ActiveRecord::Migration[5.2]
  def change
    create_table :blood_pressure_rollups, id: :uuid do |t|
      t.references :assigned_facility, type: :uuid, null: false, foreign_key: {to_table: :facilities}
      t.references :blood_pressure_facility, type: :uuid, null: false, foreign_key: {to_table: :facilities}
      t.references :blood_pressure, type: :uuid, null: false, foreign_key: true
      t.references :patient, type: :uuid, null: false, foreign_key: true

      t.integer :systolic, null: false
      t.integer :diastolic, null: false

      t.integer :period_number, null: false
      t.integer :period_type, null: false
      t.integer :year, null: false

      t.datetime :deleted_at, null: true
      t.datetime :recorded_at, null: false
      t.timestamps null: false
    end

    add_index :blood_pressure_rollups,
      [:blood_pressure_id, :patient_id, :period_number, :period_type, :year],
      name: "one_blood_pressure_per_patient_per_period",
      unique: true
  end
end
