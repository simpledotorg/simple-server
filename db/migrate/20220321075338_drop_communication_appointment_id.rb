class DropCommunicationAppointmentId < ActiveRecord::Migration[5.2]
  def change
    remove_column :communications, :appointment_id
  end
end
