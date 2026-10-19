class AddCompletedAtToDrRaiTargets < ActiveRecord::Migration[6.1]
  def up
    add_column :dr_rai_targets, :completed_at, :datetime
  end

  def down
    remove_column :dr_rai_targets, :completed_at
  end
end
