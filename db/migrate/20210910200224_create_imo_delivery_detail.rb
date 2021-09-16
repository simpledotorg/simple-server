class CreateImoDeliveryDetail < ActiveRecord::Migration[5.2]
  def change
    create_table :imo_delivery_details do |t|
      t.string "result"
      t.string "callee_phone_number", null: false
      t.timestamp "deleted_at"

      t.timestamps
    end
  end
end
