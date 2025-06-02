class CreateFlipperTables < ActiveRecord::Migration[6.1]
  def up
    unless table_exists?(:flipper_features)
      create_table :flipper_features do |t|
        t.string :key, null: false
        t.timestamps null: false
      end
      add_index :flipper_features, :key, unique: true
    end

    unless table_exists?(:flipper_gates)
      create_table :flipper_gates do |t|
        t.string :feature_key, null: false
        t.string :key, null: false
        t.string :value
        t.timestamps null: false
      end
      add_index :flipper_gates, [:feature_key, :key, :value], unique: true
    end
  end

  def down
    drop_table :flipper_gates if table_exists?(:flipper_gates)
    drop_table :flipper_features if table_exists?(:flipper_features)
  end
end
