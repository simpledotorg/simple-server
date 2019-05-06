class AddRecordedAtForRetroactiveDataEntry < ActiveRecord::Migration[5.1]
  def change
    add_column :blood_pressures, :recorded_at, :timestamp, null: true
    add_column :patients, :recorded_at, :timestamp, null: true

    # do we need indexes?
  end
end