class CreatePermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :permissions, id: :uuid do |t|
      t.string :name

      t.timestamps
      t.datetime :deleted_at, null: true
    end
  end
end
