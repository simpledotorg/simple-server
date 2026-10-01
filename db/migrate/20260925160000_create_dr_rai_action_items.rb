class CreateDrRaiActionItems < ActiveRecord::Migration[6.1]
  def up
    create_table :dr_rai_action_items do |t|
      t.references :action_plan, null: false, foreign_key: {to_table: :dr_rai_action_plans}
      t.text :body, null: false
      t.integer :position, null: false, default: 0
      t.datetime :completed_at
      t.timestamp :deleted_at
      t.timestamps
    end

    DrRai::ActionItem.reset_column_information
    DrRai::ActionPlan.reset_column_information
    DrRai::ActionPlan.backfill_action_items!
  end

  def down
    drop_table :dr_rai_action_items
  end
end
