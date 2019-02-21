class AddCaseInsensitiveUniqueIndexForUserPhoneNumbers < ActiveRecord::Migration[5.1]
  def up
    remove_index :users, :phone_number
    execute "CREATE UNIQUE INDEX unique_index_users_on_lowercase_phone_numbers ON users USING btree (lower(phone_number));"
  end

  def down
    execute "DROP INDEX unique_index_users_on_lowercase_phone_numbers;"
    add_index :users, :phone_number, unique: true
  end
end
