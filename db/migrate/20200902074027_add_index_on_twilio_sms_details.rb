class AddIndexOnTwilioSmsDetails < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :twilio_sms_delivery_details, :session_id, algorithm: :concurrently
  end
end
