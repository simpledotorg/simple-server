class AddTestDataColumnToPatients < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :test_data, :boolean, default: false, null: false
  end
end
