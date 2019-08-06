class MakeWhitelistStatusNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:exotel_phone_number_details, :whitelist_status, true)
  end
end
