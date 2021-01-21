class RemovePrescriptionDrugForeignKey < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :prescription_drugs, :teleconsultations
  end
end
