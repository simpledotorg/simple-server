class CreateTreatmentInertiaTables < ActiveRecord::Migration[5.2]
  def up
    create_table :clean_medicine_to_dosage, id: false do |t|
      t.bigint :rxcui, null: false
      t.string :medicine, null: false
      t.float :dosage, null: false
    end
    execute "COPY clean_medicine_to_dosage FROM '#{Rails.root}/config/data/treatment-inertia/clean_medicine_to_dosage.csv' WITH DELIMITER ',' CSV HEADER"

    create_table :raw_to_clean_medicine, id: false do |t|
      t.string :raw_name, null: false
      t.string :raw_dosage, null: false
      t.bigint :rxcui, null: false
    end
    execute "COPY raw_to_clean_medicine FROM '#{Rails.root}/config/data/treatment-inertia/raw_to_clean_medicine.csv' WITH DELIMITER ',' CSV HEADER"

    create_table :medicine_purpose, id: false do |t|
      t.string :name, null: false
      t.boolean :hypertension, null: false
      t.boolean :diabetes, null: false
    end
    execute "COPY medicine_purpose FROM '#{Rails.root}/config/data/treatment-inertia/medicine_purpose.csv' WITH DELIMITER ',' CSV HEADER"

    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"
    create_view :reporting_prescriptions, version: 1, materialized: true
    add_index :reporting_prescriptions, [:patient_id, :month_date], unique: true, name: "reporting_prescriptions_patient_month_date"
  end

  def down
    drop_view :reporting_prescriptions, materialized: true
    drop_table :medicine_purpose
    drop_table :raw_to_clean_medicine
    drop_table :clean_medicine_to_dosage
  end
end
