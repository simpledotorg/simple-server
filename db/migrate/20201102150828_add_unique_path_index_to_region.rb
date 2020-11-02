class AddUniquePathIndexToRegion < ActiveRecord::Migration[5.2]
  def change
    add_index :regions, :path, unique: true, using: :btree, name: :index_regions_on_unique_path
  end
end
