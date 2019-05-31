class CreateUserPermissions < ActiveRecord::Migration[5.1]
  def change
    create_table :user_permissions, id: :uuid do |t|
      t.belongs_to :user
      t.string :permission_slug
      t.belongs_to :resource, id: :uuid, polymorphic: true

      t.timestamps

      t.datetime :deleted_at, null: true # This is for discard gem
    end
  end
end
