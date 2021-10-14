class NullableFacilityIdOnDrugStocks < ActiveRecord::Migration[5.2]
  def change
    change_column_null :drug_stocks, :facility_id, true
    change_column_null :drug_stocks, :region_id, false
  end
end
