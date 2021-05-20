class DropPatientIdFromCommunications < ActiveRecord::Migration[5.2]
  def change
    remove_column :communications, :patient_id, type: :uuid, foreign_key: true
  end
end
