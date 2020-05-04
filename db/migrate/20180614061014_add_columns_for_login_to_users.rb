class AddColumnsForLoginToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :otp, :string, null: false
    add_column :users, :otp_expires_at, :datetime, null: false
    add_column :users, :access_token, :string, null: false
    add_column :users, :is_access_token_valid, :boolean, null: false
  end
end
