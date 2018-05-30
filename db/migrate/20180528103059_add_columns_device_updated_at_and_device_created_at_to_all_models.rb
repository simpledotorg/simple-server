class AddColumnsDeviceUpdatedAtAndDeviceCreatedAtToAllModels < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :device_created_at, :datetime, null: false
    add_column :patients, :device_updated_at, :datetime, null: false
    remove_column :patients, :updated_on_server_at

    add_column :addresses, :device_created_at, :datetime, null: false
    add_column :addresses, :device_updated_at, :datetime, null: false
    remove_column :addresses, :updated_on_server_at

    add_column :patient_phone_numbers, :device_created_at, :datetime, null: false
    add_column :patient_phone_numbers, :device_updated_at, :datetime, null: false
    remove_column :patient_phone_numbers, :updated_on_server_at
  end
end
