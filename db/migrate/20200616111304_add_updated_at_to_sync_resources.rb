class AddUpdatedAtToSyncResources < ActiveRecord::Migration[5.2]
  def change
    add_index :blood_pressures, :updated_at
    add_index :blood_sugars, :updated_at
    add_index :patients, :updated_at
    add_index :appointments, :updated_at
  end
end
