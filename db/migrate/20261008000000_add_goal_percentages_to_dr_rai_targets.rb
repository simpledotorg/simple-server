class AddGoalPercentagesToDrRaiTargets < ActiveRecord::Migration[6.1]
  def up
    add_column :dr_rai_targets, :baseline_percentage, :integer
    add_column :dr_rai_targets, :goal_percentage, :integer
  end

  def down
    remove_column :dr_rai_targets, :goal_percentage
    remove_column :dr_rai_targets, :baseline_percentage
  end
end
