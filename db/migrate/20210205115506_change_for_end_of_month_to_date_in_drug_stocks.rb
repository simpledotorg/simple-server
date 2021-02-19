class ChangeForEndOfMonthToDateInDrugStocks < ActiveRecord::Migration[5.2]
  def change
    change_column :drug_stocks, :for_end_of_month, :date
  end
end
