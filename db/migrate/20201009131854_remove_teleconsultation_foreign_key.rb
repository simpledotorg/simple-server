class RemoveTeleconsultationForeignKey < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :teleconsultations, :patients
  end
end
