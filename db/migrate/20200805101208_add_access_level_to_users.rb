class AddAccessLevelToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :access_level, :string
  end
end
