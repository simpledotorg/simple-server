class CreateTwilioSmsDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :twilio_sms_delivery_details do |t|
      t.string :session_id
      t.string :result
      t.string :callee_phone_number, null: false
      t.timestamp :delivered_on
      t.timestamps
    end
  end
end
