class AddDrugStockFieldsToProtocolDrugs < ActiveRecord::Migration[5.2]
  def change
    add_column :protocol_drugs, :drug_category, :string
    add_column :protocol_drugs, :stock_tracked, :boolean, null: false, default: false
  end
end
