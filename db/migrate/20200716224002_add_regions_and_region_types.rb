class AddRegionsAndRegionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table(:regions, id: :uuid) do |t|
      t.string :name, null: false
      t.integer :level, null: false
      t.string :description
      t.string :slug, null: false
      t.uuid :parent_region_id
      t.string :parent_region_type
      t.datetime :deleted_at
      t.timestamps null: false
    end

    change_table(:facility_groups) do |t|
      t.uuid :parent_region_id, null: true
    end
  end
end
