class DropRegionType < ActiveRecord::Migration[5.2]
  def change
    remove_column :regions, :region_type_id
    drop_table :region_types
    add_column :regions, :type, :string, null: false
  end
end
