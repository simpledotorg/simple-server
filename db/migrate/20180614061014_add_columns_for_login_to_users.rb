class AddColumnsForLoginToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :otp, :string
    add_column :users, :otp_valid_until, :datetime
  end
end
