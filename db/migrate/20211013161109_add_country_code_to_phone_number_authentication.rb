class AddCountryCodeToPhoneNumberAuthentication < ActiveRecord::Migration[5.2]
  def change
    add_column :phone_number_authentications, :country_code, :string, null: true
  end
end
