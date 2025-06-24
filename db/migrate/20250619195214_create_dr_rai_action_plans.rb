class CreateDrRaiActionPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :dr_rai_action_plans do |t|
      t.string :statement
      t.text :actions
      t.references :dr_rai_indicator, null: false, foreign_key: true
      t.references :dr_rai_target, null: false, foreign_key: true
      t.references :region, null: false, foreign_key: true, type: :uuid

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
