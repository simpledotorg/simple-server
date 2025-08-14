class AddDeletedAtToDrRaiDataTitrations < ActiveRecord::Migration[6.1]
  def change
    add_column :dr_rai_data_titrations, :deleted_at, :timestamp
  end
end
