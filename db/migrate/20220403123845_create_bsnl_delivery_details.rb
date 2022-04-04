class CreateBsnlDeliveryDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :bsnl_delivery_details, id: :uuid do |t|
      t.string :message_id
      t.string :message_status
      t.string :message_status_description
      t.string :recipient_number, null: false
      t.string :dlt_template_id
      t.string :result
      t.timestamp :delivered_on
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
