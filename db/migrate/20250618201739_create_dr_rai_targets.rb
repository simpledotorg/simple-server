class CreateDrRaiTargets < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_targets do |t|
      t.string :type
      t.integer :numeric_value
      t.string :numeric_units
      t.boolean :completed
      t.jsonb :period
      t.timestamp :deleted_at

      t.timestamps
    end
  end
end
