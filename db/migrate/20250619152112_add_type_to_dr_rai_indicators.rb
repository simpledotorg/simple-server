class AddTypeToDrRaiIndicators < ActiveRecord::Migration[6.1]
  def change
    add_column :dr_rai_indicators, :type, :string
  end
end
