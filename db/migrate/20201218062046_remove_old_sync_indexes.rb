class RemoveOldSyncIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :patients, :updated_at
    remove_index :blood_pressures, :updated_at
    remove_index :blood_sugars, :updated_at
    remove_index :appointments, :updated_at
    remove_index :prescription_drugs, :updated_at
  end
end
