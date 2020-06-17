class AddJsonTeleconsultationNumbersToFacilities < ActiveRecord::Migration[5.2]
  def change
    add_column :facilities, :teleconsultation_phone_numbers, :jsonb, null: false, default: []
  end
end
