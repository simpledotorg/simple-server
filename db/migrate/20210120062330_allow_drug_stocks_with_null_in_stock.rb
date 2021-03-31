class AllowDrugStocksWithNullInStock < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:drug_stocks, :in_stock, true)
  end
end
