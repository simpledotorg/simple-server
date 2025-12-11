class MakeDrRaiIndicatorsIdNullableInDrRaiTargets < ActiveRecord::Migration[6.1]
  def change
    change_column_null :dr_rai_targets, :dr_rai_indicators_id, true
  end
end
