class AddDrugStockParentIdToFacility < ActiveRecord::Migration[5.2]
  def change
    add_column :facilities, :drug_stock_parent_id, :uuid, foreign_key: true
  end
end
