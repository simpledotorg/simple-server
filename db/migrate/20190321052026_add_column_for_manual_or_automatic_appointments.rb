class AddColumnForManualOrAutomaticAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :is_automatic, :boolean, :default => false
    add_index :appointments, :is_automatic
  end
end
