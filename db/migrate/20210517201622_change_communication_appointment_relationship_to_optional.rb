class ChangeCommunicationAppointmentRelationshipToOptional < ActiveRecord::Migration[5.2]
  def change
    change_column_null :communications, :appointment_id, true
  end
end
