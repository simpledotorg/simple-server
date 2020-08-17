class AddAccessLevelToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :access_level, :string
    add_index :users, :access_level
  end
end
