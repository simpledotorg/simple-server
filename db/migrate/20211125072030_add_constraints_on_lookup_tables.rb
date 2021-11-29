class AddConstraintsOnLookupTables < ActiveRecord::Migration[5.2]
  def change
    Seed::DrugLookupTablesSeeder.drop
    add_index :raw_to_clean_medicines, [:raw_name, :raw_dosage], unique: true, name: "raw_to_clean_medicines_unique_name_and_dosage"
    add_index :clean_medicine_to_dosages, [:medicine, :dosage, :rxcui], unique: true, name: "clean_medicine_to_dosages__unique_name_and_dosage"
    add_index :medicine_purposes, [:name], unique: true, name: "medicine_purposes_unique_name"
    add_foreign_key(:clean_medicine_to_dosages, :medicine_purposes, column: :medicine, primary_key: :name)
    Seed::DrugLookupTablesSeeder.create
  end
end
