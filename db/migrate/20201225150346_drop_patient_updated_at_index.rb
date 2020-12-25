class DropPatientUpdatedAtIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :patients, :updated_at
  end
end
