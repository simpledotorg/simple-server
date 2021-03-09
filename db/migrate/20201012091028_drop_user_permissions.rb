class DropUserPermissions < ActiveRecord::Migration[5.2]
  def change
    drop_table :user_permissions
  end
end
