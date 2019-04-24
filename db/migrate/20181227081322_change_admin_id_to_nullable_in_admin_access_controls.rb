class ChangeAdminIdToNullableInAdminAccessControls < ActiveRecord::Migration[5.1]
  def change
    change_column_null :admin_access_controls, :admin_id, true
  end
end
