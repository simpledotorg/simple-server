class AddUserTypeToMasterUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :master_users, :user_type, :string
  end
end
