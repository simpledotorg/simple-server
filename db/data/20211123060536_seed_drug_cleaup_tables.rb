class SeedDrugCleaupTables < ActiveRecord::Migration[5.2]
  def up
    execute "COPY clean_medicine_to_dosage FROM '#{Rails.root}/config/data/treatment-inertia/clean_medicine_to_dosage.csv' WITH DELIMITER ',' CSV HEADER"
    execute "COPY raw_to_clean_medicine FROM '#{Rails.root}/config/data/treatment-inertia/raw_to_clean_medicine.csv' WITH DELIMITER ',' CSV HEADER"
    execute "COPY medicine_purpose FROM '#{Rails.root}/config/data/treatment-inertia/medicine_purpose.csv' WITH DELIMITER ',' CSV HEADER"
  end

  def down
    execute "TRUNCATE clean_medicine_to_dosage"
    execute "TRUNCATE raw_to_clean_medicine"
    execute "TRUNCATE medicine_purpose"
  end
end
