class RemoveRegionFromDrRaiIndicators < ActiveRecord::Migration[6.1]
  def change
    remove_reference :dr_rai_indicators, :region, null: false, foreign_key: true
  end
end
