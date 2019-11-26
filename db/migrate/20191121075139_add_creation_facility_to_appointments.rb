class AddCreationFacilityToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :creation_facility_id, :uuid
  end
end
