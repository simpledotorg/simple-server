class AddIndexToDrRaiDataTitrations < ActiveRecord::Migration[6.1]
  def change
    add_index :dr_rai_data_titrations, [:month_date, :facility_name], unique: true
  end
end
