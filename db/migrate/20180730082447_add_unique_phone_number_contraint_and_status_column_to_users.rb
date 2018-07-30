class AddUniquePhoneNumberContraintAndStatusColumnToUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :phone_number, unique: true
    add_column :users, :status, :string, default: 'waiting_for_approval'
  end
end
