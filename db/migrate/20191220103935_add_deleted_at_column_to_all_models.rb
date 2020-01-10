class AddDeletedAtColumnToAllModels < ActiveRecord::Migration[5.1]
  def change
    add_column :call_logs, :deleted_at, :datetime
    add_index :call_logs, :deleted_at

    add_column :exotel_phone_number_details, :deleted_at, :datetime
    add_index :exotel_phone_number_details, :deleted_at

    add_column :observations, :deleted_at, :datetime
    add_index :observations, :deleted_at

    add_column :twilio_sms_delivery_details, :deleted_at, :datetime
    add_index :twilio_sms_delivery_details, :deleted_at

    add_column :audit_logs, :deleted_at, :datetime
  end
end
