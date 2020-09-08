class AddIndexToPrescriptionDrugs < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :prescription_drugs, :updated_at, algorithm: :concurrently
  end
end
