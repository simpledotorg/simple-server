class CreatePhoneNumberAuthentications < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_number_authentications, id: :uuid do |t|
      t.string :phone_number, unique: true, null: false
      t.string :password_digest, null: false
      t.string :otp, null: false
      t.datetime :otp_expires_at, null: false
      t.datetime :logged_in_at
      t.string :access_token, null: false

      t.uuid :registration_facility_id

      t.timestamps

      # This is for discard gem
      t.datetime :deleted_at, null: true
    end
  end
end
