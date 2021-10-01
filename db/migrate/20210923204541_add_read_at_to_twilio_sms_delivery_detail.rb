class AddReadAtToTwilioSmsDeliveryDetail < ActiveRecord::Migration[5.2]
  def change
    add_column :twilio_sms_delivery_details, :read_at, :timestamp, null: true
  end
end
