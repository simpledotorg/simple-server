class DropPassportAuthenticationPatientId < ActiveRecord::Migration[5.1]
  def change
    remove_column :passport_authentications, :patient_id, :uuid
  end
end
