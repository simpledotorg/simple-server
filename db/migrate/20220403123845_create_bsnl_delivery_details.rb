class CreateBsnlDeliveryDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :bsnl_delivery_details do |t|
      t.string :message_id, null: false
      t.string :message_status
      t.string :result
      t.string :recipient_number, null: false
      t.string :dlt_template_id, null: false
      t.timestamp :delivered_on
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
