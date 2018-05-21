class CreatePhoneNumbers < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_numbers, id: false do |t|
      t.uuid :id, primary_key: true
      t.string :number
      t.string :phone_type
      t.boolean :active

      t.timestamps
    end

    create_table :patient_phone_numbers, id: false do |t|
      t.uuid :patient_id, references: :patients
      t.uuid :phone_number_id, references: :phone_numbers
      t.index [:phone_number_id, :patient_id], :unique => true
    end
  end
end
