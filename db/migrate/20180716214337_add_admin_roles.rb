class AddAdminRoles < ActiveRecord::Migration[5.1]
  def change
    add_column :admins, :role, :integer, default: 0, null: false
  end
end
