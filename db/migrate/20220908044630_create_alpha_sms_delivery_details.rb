class CreateAlphaSmsDeliveryDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :alpha_sms_delivery_details do |t|
      t.string :request_id, null: false
      t.string :request_status
      t.string :recipient_number, null: false
      t.string :message
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
