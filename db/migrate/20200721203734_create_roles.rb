class CreateRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.uuid :user_id, null: false, foreign_key: true
      t.uuid :resource_id, null: false
      t.string :resource_type, null: false
      t.datetime :deleted_at
      t.timestamps null: false
    end
  end
end
