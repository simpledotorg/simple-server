class AddAssignedFacilityToPatients < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :assigned_facility_id, :uuid
    add_index :patients, :assigned_facility_id
  end
end
