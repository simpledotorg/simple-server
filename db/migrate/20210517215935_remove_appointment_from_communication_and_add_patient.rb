class RemoveAppointmentFromCommunicationAndAddPatient < ActiveRecord::Migration[5.2]
  def change
    remove_column :communications, :appointment_id
    add_reference :communications, :patient, null: true, foreign_key: true, type: :uuid
  end
end
