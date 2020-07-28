class AddAccessesToUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :accesses, id: :uuid do |t|
      t.references :user, null: false, index: true, type: :uuid, foreign_key: true
      t.string :mode, null: false, index: true

      t.references :scope,
        type: :uuid,
        polymorphic: true,
        index: {unique: true, name: "idx_accesses_on_scope_type_and_id"}

      t.timestamps null: false
      t.datetime :deleted_at, null: true
    end
  end
end
