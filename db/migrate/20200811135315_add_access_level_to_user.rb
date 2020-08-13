class AddAccessLevelToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :access_level, :string, null: false
    add_index :users, :access_level
  end
end
