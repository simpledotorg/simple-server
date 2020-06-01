class RenameOtpValidUntilToOtpExpiresAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :passport_authentications, :otp_valid_until, :otp_expires_at
    rename_column :phone_number_authentications, :otp_valid_until, :otp_expires_at
  end
end
