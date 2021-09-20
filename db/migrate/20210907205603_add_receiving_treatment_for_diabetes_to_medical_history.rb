class AddReceivingTreatmentForDiabetesToMedicalHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :medical_histories, :receiving_treatment_for_diabetes, :text, required: false
  end
end
