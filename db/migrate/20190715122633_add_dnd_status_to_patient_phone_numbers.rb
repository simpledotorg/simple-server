class AddDndStatusToPatientPhoneNumbers < ActiveRecord::Migration[5.1]
  def change
    add_column :patient_phone_numbers, :dnd_status, :boolean, null: false, default: true
    add_index :patient_phone_numbers, :dnd_status
  end
end
