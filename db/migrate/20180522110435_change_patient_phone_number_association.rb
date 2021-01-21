class ChangePatientPhoneNumberAssociation < ActiveRecord::Migration[5.1]
  def change
    drop_table :patient_phone_numbers, id: false do |t|
      t.uuid :patient_id, references: :patients
      t.uuid :phone_number_id, references: :phone_numbers
      t.index [:phone_number_id, :patient_id], unique: true
    end
    rename_table :phone_numbers, :patient_phone_numbers
    add_column :patient_phone_numbers, :patient_id, :uuid
    add_foreign_key :patient_phone_numbers, :patients
  end
end
