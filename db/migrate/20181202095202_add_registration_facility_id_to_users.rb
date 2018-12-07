class AddRegistrationFacilityIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :registration_facility_id, :uuid
    add_index :users, :registration_facility_id
  end
end
