class SeedDrugLookupTables < ActiveRecord::Migration[5.2]
  def up
    Seed::DrugLookupTablesSeeder.import
  end

  def down
    Seed::DrugLookupTablesSeeder.truncate
  end
end
