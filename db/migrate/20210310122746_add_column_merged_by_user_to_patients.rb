class AddColumnMergedByUserToPatients < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :merged_by_user_id, :uuid
    add_foreign_key :patients, :users, column: :merged_by_user_id
  end
end
