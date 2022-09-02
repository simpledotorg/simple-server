class RefreshDrugLookupTables < ActiveRecord::Migration[5.2]
  def up
    Seed::DrugLookupTablesSeeder.truncate_and_import
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
