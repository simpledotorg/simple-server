class AddHypertensionToMedicalHistories < ActiveRecord::Migration[5.1]
  def change
    add_column :medical_histories, :hypertension, :text
  end
end
