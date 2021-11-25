class SeedDrugLookupTables < ActiveRecord::Migration[5.2]
  def up
    Seed::DrugLookupTablesSeeder.create
  end

  def down
    Seed::DrugLookupTablesSeeder.drop
  end
end
