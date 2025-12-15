class AddDiagnosedConfirmedAtIndexToPatients < ActiveRecord::Migration[6.1]
  self.disable_ddl_transaction = true

  def up
    add_index :patients, [:diagnosed_confirmed_at], name: "index_patients_on_diagnosed_confirmed_at", algorithm: :concurrently
  end

  def down
    remove_index :patients, name: "index_patients_on_diagnosed_confirmed_at"
  end
end
