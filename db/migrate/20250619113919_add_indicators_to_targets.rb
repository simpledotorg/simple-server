class AddIndicatorsToTargets < ActiveRecord::Migration[6.1]
  def change
    add_reference :dr_rai_targets, :dr_rai_indicators, null: false, foreign_key: true
  end
end
