class AddDiagnosedConfirmedAtToPatients < ActiveRecord::Migration[6.1]
  def up
    add_column :patients, :diagnosed_confirmed_at, :datetime

    execute <<~SQL.squish
      UPDATE patients
      SET diagnosed_confirmed_at = device_created_at
      WHERE diagnosed_confirmed_at IS NULL
        AND device_created_at IS NOT NULL;
    SQL
  end

  def down
    remove_column :patients, :diagnosed_confirmed_at
  end
end
