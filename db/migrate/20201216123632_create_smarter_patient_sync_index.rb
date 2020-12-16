class CreateSmarterPatientSyncIndex < ActiveRecord::Migration[5.2]
  def change
    remove_index :patients, :updated_at if index_exists?(:patients, :updated_at)

    add_index :patients, [:id, :updated_at]
  end
end
