class AddPercentageValueToDrRaiTargets < ActiveRecord::Migration[6.1]
  def up
    add_column :dr_rai_targets, :percentage_value, :integer
  end

  def down
    remove_column :dr_rai_targets, :percentage_value
  end
end
