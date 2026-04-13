class UnlinkPatientsFromPatientAttributes < ActiveRecord::Migration[6.1]
  def change
    remove_foreign_key :patient_attributes, :patients
  end
end
