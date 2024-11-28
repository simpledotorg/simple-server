class AddDeviceTimestampsToPatientAttributes < ActiveRecord::Migration[6.1]
  def change
    add_column :patient_attributes, :device_created_at, :timestamp
    add_column :patient_attributes, :device_updated_at, :timestamp
  end
end
