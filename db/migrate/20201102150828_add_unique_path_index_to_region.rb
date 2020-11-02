class AddUniquePathIndexToRegion < ActiveRecord::Migration[5.2]
  def change
    remove_index :regions, :path
    add_index :regions, :path, unique: true
  end
end
