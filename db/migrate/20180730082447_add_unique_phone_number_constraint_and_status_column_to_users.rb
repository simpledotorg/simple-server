class AddUniquePhoneNumberConstraintAndStatusColumnToUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :phone_number, unique: true
    add_column :users, :sync_approval_status, :string
    remove_column :users, :is_access_token_valid
  end
end
