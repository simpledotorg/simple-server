class AddUpdatedOnServerAtToPatientAddressAndPhoneNumbers < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :updated_on_server_at, :timestamp, null: false
    add_column :addresses, :updated_on_server_at, :timestamp, null: false
    add_column :phone_numbers, :updated_on_server_at, :timestamp, null: false
    add_column :patient_phone_numbers, :updated_on_server_at, :timestamp, null: false
    add_index :patients, :updated_on_server_at
    add_index :addresses, :updated_on_server_at
    add_index :phone_numbers, :updated_on_server_at
    add_index :patient_phone_numbers, :updated_on_server_at
  end
end
