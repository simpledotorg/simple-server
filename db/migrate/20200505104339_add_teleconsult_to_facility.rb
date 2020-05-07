class AddTeleconsultToFacility < ActiveRecord::Migration[5.1]
  def change
    add_column :facilities, :enable_teleconsultation, :boolean, default: false, null: false
    add_column :facilities, :teleconsultation_phone_number, :string
    add_column :facilities, :teleconsultation_isd_code, :string
  end
end
