class CreateUserResources < ActiveRecord::Migration[5.2]
  def change
    create_table :user_resources do |t|
      t.uuid :user_id, null: false, index: true
      t.uuid :resource_id, null: false, index: true
      t.string :resource_type, null: false, index: true

      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end
