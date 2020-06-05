class AddDeletionColumnsToPatients < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :deleted_by_user_id, :uuid, index: true
    add_column :patients, :deleted_reason, :string, index: true
  end
end
