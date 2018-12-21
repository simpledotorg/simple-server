class AddInitialRegistrationDetailsToPatient < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :registration_facility_id, :uuid
    add_index :patients, :registration_facility_id

    add_column :patients, :registration_user_id, :uuid
    add_index :patients, :registration_user_id
  end
end
