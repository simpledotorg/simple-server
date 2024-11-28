class AddDeletedAtToPatientAttributes < ActiveRecord::Migration[6.1]
  def change
    add_column :patient_attributes, :deleted_at, :timestamp
  end
end
