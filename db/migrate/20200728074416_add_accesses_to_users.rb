class AddAccessesToUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :accesses, id: :uuid do |t|
      t.references :user, null: false, index: true, type: :uuid, foreign_key: true

      t.references :resource,
        type: :uuid,
        polymorphic: true

      t.index [:user_id, :resource_id, :resource_type], unique: true

      t.timestamps null: false
      t.datetime :deleted_at, null: true
    end
  end
end
