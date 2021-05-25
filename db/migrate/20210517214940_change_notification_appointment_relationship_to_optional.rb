class ChangeNotificationAppointmentRelationshipToOptional < ActiveRecord::Migration[5.2]
  def change
    change_column_null :notifications, :appointment_id, true
  end
end
