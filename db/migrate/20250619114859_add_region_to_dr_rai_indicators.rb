class AddRegionToDrRaiIndicators < ActiveRecord::Migration[6.1]
  def change
    add_reference :dr_rai_indicators, :region, null: false, foreign_key: true, type: :uuid
  end
end
