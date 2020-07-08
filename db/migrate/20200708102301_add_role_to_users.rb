class AddRoleToUsers < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :role, :designation
    add_column :users, :role_id, :uuid, index: true, null: true
  end
end
