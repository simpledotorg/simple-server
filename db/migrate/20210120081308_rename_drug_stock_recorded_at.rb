class RenameDrugStockRecordedAt < ActiveRecord::Migration[5.2]
  def change
    rename_column :drug_stocks, :recorded_at, :for_end_of_month
  end
end
