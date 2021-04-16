class DropPatientMergeFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :patients, :merged_into_patient_id, :string
    remove_column :patients, :merged_by_user_id, :string
  end
end
