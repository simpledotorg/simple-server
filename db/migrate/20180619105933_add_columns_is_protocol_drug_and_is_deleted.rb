class AddColumnsIsProtocolDrugAndIsDeleted < ActiveRecord::Migration[5.1]
  def change
    add_column :prescription_drugs, :is_protocol_drug, :boolean, null: false
    add_column :prescription_drugs, :is_deleted, :boolean, null: false
  end
end
