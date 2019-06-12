class AddRecordedAtForRetroactiveDataEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :blood_pressures, :recorded_at, :timestamp, null: true
    add_column :patients, :recorded_at, :timestamp, null: true

    add_index :patients, :recorded_at
    add_index :blood_pressures, :recorded_at
  end
end
