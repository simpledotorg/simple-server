class CreateUserAccesses < ActiveRecord::Migration[5.2]
  def change
    create_table :accesses, id: :uuid do |t|
      t.references :user, null: false, index: true, type: :uuid, foreign_key: true
      t.references :role, null: false, index: true, type: :uuid, foreign_key: true

      t.references :resourceable,
        type: :uuid,
        polymorphic: true,
        index: {unique: true, name: "idx_accesses_on_resourceable_type_and_id"}

      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end
