class DropAdminsAndAdminAccessControls < ActiveRecord::Migration[5.1]
  def change
    drop_table :admin_access_controls
    drop_table :admins
  end
end
