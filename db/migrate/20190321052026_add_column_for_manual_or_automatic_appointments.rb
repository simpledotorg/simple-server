class AddColumnForManualOrAutomaticAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :appointment_type, :string, null: false, default: 'manual'
    add_index :appointments, :appointment_type
  end
end
