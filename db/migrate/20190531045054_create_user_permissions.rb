class CreateUserPermissions < ActiveRecord::Migration[5.1]
  def change
    create_table :user_permissions, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :permission_slug
      t.belongs_to :resource, id: :uuid, polymorphic: true, null: false

      t.timestamps

      t.datetime :deleted_at, null: true # This is for discard gem
    end
  end
end
