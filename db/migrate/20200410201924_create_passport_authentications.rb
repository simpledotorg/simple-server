class CreatePassportAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :passport_authentications do |t|
      t.string :access_token, null: false
      t.string :otp, null: false
      t.datetime :otp_valid_until, null: false
      t.uuid :patient_id, null: false
      t.uuid :patient_business_identifier_id, null: false

      t.timestamps
    end
  end
end
