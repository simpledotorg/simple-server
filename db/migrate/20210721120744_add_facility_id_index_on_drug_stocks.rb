class AddFacilityIdIndexOnDrugStocks < ActiveRecord::Migration[5.2]
  def change
    add_index :drug_stocks, :facility_id unless index_exists?(:drug_stocks, :facilities)
  end
end
