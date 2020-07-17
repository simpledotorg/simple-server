class AddIndexToPatientsOnAssignedFacility < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :patients, :assigned_facility_id, algorithm: :concurrently
  end
end
