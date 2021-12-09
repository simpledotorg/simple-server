class UpdatePrescriptionsToHaveUniqueMedicines < ActiveRecord::Migration[5.2]
  def change
    Seed::DrugLookupTablesSeeder.truncate
    update_view :reporting_prescriptions, version: 3, revert_to_version: 2, materialized: true
    Seed::DrugLookupTablesSeeder.import
  end
end
