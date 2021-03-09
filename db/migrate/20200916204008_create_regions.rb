class CreateRegions < ActiveRecord::Migration[5.2]
  def change
    create_table :region_kinds, id: :uuid do |t|
      t.string :name, null: false
      t.ltree :path, null: false

      t.datetime :deleted_at
      t.timestamps null: false

      t.index :name, unique: true
      t.index :path, using: :gist
    end

    create_table :regions, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :description

      t.references :source, type: :uuid, polymorphic: true
      t.references :region_kind, type: :uuid, foreign_key: true, index: true

      t.ltree :path
      t.datetime :deleted_at
      t.timestamps null: false

      t.index :slug, unique: true
      t.index :path, using: :gist
    end
  end
end
