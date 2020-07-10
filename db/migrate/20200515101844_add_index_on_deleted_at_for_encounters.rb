class AddIndexOnDeletedAtForEncounters < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :encounters, :deleted_at, algorithm: :concurrently
  end
end
