class AddDrugStockFieldsToProtocolDrugs < ActiveRecord::Migration[5.2]
  def change
    add_column :protocol_drugs, :drug_type, :string
    add_column :protocol_drugs, :track_stock, :boolean, null: false, default: false
  end
end
