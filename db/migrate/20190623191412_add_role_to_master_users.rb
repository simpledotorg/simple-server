class AddRoleToMasterUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :master_users, :role, :string
  end
end
