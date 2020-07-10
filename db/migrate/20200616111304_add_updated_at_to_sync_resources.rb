class AddUpdatedAtToSyncResources < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :blood_pressures, :updated_at, algorithm: :concurrently
    add_index :blood_sugars, :updated_at, algorithm: :concurrently
    add_index :patients, :updated_at, algorithm: :concurrently
    add_index :appointments, :updated_at, algorithm: :concurrently
  end
end
