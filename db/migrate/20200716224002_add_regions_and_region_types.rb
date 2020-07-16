class AddRegionsAndRegionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table(:region_types, id: :uuid) do |t|
      t.string :name, null: false
      t.timestamps null: false
    end

    create_table(:regions, id: :uuid) do |t|
      t.string :name, null: false
      t.string :description
      t.string :slug, null: false
      t.references :parent, polymorphic: true, type: :uuid, null: false
      t.references :region_type, type: :uuid, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
