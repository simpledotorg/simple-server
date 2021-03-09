class RenameToRegionTypes < ActiveRecord::Migration[5.2]
  def change
    rename_table :region_kinds, :region_types
    change_table :regions do |t|
      t.rename :region_kind_id, :region_type_id
    end
  end
end
