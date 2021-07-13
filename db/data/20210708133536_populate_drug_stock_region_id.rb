class PopulateDrugStockRegionId < ActiveRecord::Migration[5.2]
  def up
    DrugStock.find_each do |drug_stock|
      drug_stock.update!(region_id: drug_stock.facility.region.id)
    end
  end

  def down
    DrugStock.update_all(region_id: nil)
  end
end
