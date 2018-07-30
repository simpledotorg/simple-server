class AddUniquePhoneNumberContraintAndStatusColumnToUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :phone_number, unique: true
  end
end
