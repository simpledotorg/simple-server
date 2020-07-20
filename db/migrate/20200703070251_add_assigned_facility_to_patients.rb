class AddAssignedFacilityToPatients < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :assigned_facility_id, :uuid
    add_foreign_key :patients, :facilities, column: :assigned_facility_id
    add_foreign_key :patients, :facilities, column: :registration_facility_id
  end
end
