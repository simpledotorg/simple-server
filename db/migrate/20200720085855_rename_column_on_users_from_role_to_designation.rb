class RenameColumnOnUsersFromRoleToDesignation < ActiveRecord::Migration[5.2]
  def change
    rename_column :users, :role, :designation
  end
end
