class AddIndexToDrRaiDataStatins < ActiveRecord::Migration[6.1]
  def change
    add_index :dr_rai_data_statins, [:month_date, :aggregate_root], unique: true
  end
end
