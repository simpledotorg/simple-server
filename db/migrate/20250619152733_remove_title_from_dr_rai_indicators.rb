class RemoveTitleFromDrRaiIndicators < ActiveRecord::Migration[6.1]
  def change
    remove_column :dr_rai_indicators, :title, :string
  end
end
