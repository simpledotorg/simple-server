class DropTeleconsultationFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :facilities, :teleconsultation_phone_number, :string
    remove_column :facilities, :teleconsultation_isd_code, :string
    remove_column :facilities, :teleconsultation_phone_numbers, :jsonb, null: false, default: []
  end
end
