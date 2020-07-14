class CreateJoinTableRolesPermissions < ActiveRecord::Migration[5.2]
  def change
    create_join_table(:permissions, :roles, column_options: {type: :uuid})

    add_index :permissions_roles, [:permission_id, :role_id]
  end
end
