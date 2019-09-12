class AddUserIdToPrescriptionDrugs < ActiveRecord::Migration[5.1]
  def change
    add_column :prescription_drugs, :user_id, :uuid, index: true, null: true
  end
end
