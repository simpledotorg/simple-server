class CreateEtlDataWarehouseTables < ActiveRecord::Migration[5.2]
  def change
    create_table :blood_pressure_observations_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.integer :months_since_registration
      t.date :calendar_month
      t.integer :systolic
      t.integer :diastolic
      t.integer :months_since_bp_observation
      t.timestamps
    end

    create_table :encounters_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.date :calendar_month
      t.integer :months_since_registration
      t.integer :months_since_encounter
      t.timestamps
    end

    create_table :patient_states_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.date :calendar_month
      t.integer :months_since_registration
      t.string :diagnosed_disease_state
      t.string :protocol_state
      t.string :treatment_state
      t.string :bp_observation_state
      t.uuid :assigned_facility_id
      t.timestamps
    end

    create_table :medicine_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.date :calendar_month
      t.integer :months_since_registration
      t.decimal :amlodipine
      t.decimal :aspirin
      t.decimal :atenolol
      t.decimal :atorvastatin
      t.decimal :captopril
      t.decimal :chlorthalidone
      t.decimal :clopidogrel
      t.decimal :enalapril
      t.decimal :glibenclamide
      t.decimal :gliclazide
      t.decimal :glimepiride
      t.decimal :glipizide
      t.decimal :hydrochlorothiazide
      t.decimal :lisinopril
      t.decimal :losartan
      t.decimal :losartan_amlodipine
      t.decimal :losartan_hydrochlorathiazide
      t.decimal :metoprolol
      t.decimal :metoprolol_xl
      t.decimal :metformin
      t.decimal :metformin_sr
      t.decimal :propranolol
      t.decimal :rosuvastatin
      t.decimal :sitagliptin
      t.decimal :spironolactone
      t.decimal :telmisartan
      t.decimal :telvas_3d
      t.decimal :vildagliptin
      t.decimal :other_bp_medications
      t.timestamps
    end

    create_table :protocol_steps_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.uuid :protocol_id
      t.date :calendar_month
      t.integer :months_since_registration
      t.integer :step
      t.timestamps
    end

    create_table :visit_counts_over_time, id: :uuid do |t|
      t.uuid :patient_id, null: false
      t.date :calendar_month
      t.integer :months_since_registration
      t.integer :encounters
      t.integer :bp_observations
      t.timestamps
    end
  end
end
