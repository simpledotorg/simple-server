class AddPassportAuthenticationIndices < ActiveRecord::Migration[5.1]
  def change
    add_index :passport_authentications, :patient_id
    add_index :passport_authentications, :patient_business_identifier_id, name: :index_passport_auth_on_business_id
  end
end
