class AddUserIdToAdminAccessControls < ActiveRecord::Migration[5.1]
  def change
    add_column :admin_access_controls, :user_id, :uuid, index: true
  end
end
