class AddAgeAndAgeUpdatedAtToPatients < ActiveRecord::Migration[5.1]
  def change
    rename_column :patients, :age_when_created, :age
    add_column :patients, :age_updated_at, :timestamp
  end
end
