class AddCountryCodeToPatientPhoneNumber < ActiveRecord::Migration[5.2]
  def change
    add_column :patient_phone_numbers, :country_code, :string, null: true
  end
end
