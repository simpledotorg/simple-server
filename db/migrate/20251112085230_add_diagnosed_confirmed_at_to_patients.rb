class AddDiagnosedConfirmedAtToPatients < ActiveRecord::Migration[6.1]
  def up
    add_column :patients, :diagnosed_confirmed_at, :datetime
  end

  def down
    remove_column :patients, :diagnosed_confirmed_at
  end
end
