class CreateJoinTableRolesPermissions < ActiveRecord::Migration[5.2]
  def change
    create_join_table :roles, :permissions

    add_index :permissions_roles, [:permission_id, :role_id]
  end
end
