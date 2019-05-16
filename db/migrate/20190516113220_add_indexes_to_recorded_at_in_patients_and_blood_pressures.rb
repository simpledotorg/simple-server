class AddIndexesToRecordedAtInPatientsAndBloodPressures < ActiveRecord::Migration[5.1]
  def change
    add_index :patients, :recorded_at
    add_index :blood_pressures, :recorded_at
  end
end
