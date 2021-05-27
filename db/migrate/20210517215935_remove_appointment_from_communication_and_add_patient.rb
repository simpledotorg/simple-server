class RemoveAppointmentFromCommunicationAndAddPatient < ActiveRecord::Migration[5.2]
  def change
    add_reference :communications, :patient, null: true, foreign_key: true, type: :uuid
  end
end
