class CreateExotelPhoneNumberDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :exotel_phone_number_details, id: :uuid do |t|
      t.belongs_to :patient_phone_number, type: :uuid, null: false, foreign_key: true
      t.string :whitelist_status, null: false
      t.timestamp :whitelist_status_valid_until

      t.timestamps
    end
  end
end
