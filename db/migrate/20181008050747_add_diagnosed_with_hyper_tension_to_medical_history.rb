class AddDiagnosedWithHyperTensionToMedicalHistory < ActiveRecord::Migration[5.1]
  def change
    add_column :medical_histories, :diagnosed_with_hypertension, :boolean, null: true
  end
end
