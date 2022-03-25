class CreateConfigurations < ActiveRecord::Migration[5.2]
  def change
    create_table :configurations, id: :uuid do |t|
      t.string :name, null: false
      t.string :value, null: false

      t.timestamp :deleted_at
      t.timestamps
    end

    add_index :configurations, :name, unique: true
  end
end
