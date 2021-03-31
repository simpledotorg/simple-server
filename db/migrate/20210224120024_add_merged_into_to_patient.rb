class AddMergedIntoToPatient < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :merged_into_patient_id, :uuid
    add_foreign_key :patients, :patients, column: :merged_into_patient_id
  end
end
