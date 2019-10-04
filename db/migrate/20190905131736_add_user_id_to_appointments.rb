class AddUserIdToAppointments < ActiveRecord::Migration[5.1]
  def change
    add_column :appointments, :user_id, :uuid, index: true, null: true
  end
end
