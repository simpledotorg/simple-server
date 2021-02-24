class AddMergedIntoToPatient < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :merged_into, :uuid
    add_foreign_key :patients, :patients, column: :merged_into
  end
end
