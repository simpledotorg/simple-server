class AddLockoutsToPhoneNumberAuthentication < ActiveRecord::Migration[5.2]
  def change
    add_column :phone_number_authentications, :failed_attempts, :integer, default: 0, null: false
    add_column :phone_number_authentications, :locked_at, :datetime
  end
end
