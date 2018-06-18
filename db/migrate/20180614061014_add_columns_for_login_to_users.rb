class AddColumnsForLoginToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :otp, :string
    add_column :users, :otp_valid_until, :datetime
    add_column :users, :access_token, :string
    add_column :users, :is_access_token_valid, :boolean
  end
end
