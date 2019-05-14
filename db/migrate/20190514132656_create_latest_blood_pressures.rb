class CreateLatestBloodPressures < ActiveRecord::Migration[5.1]
  def change
    create_view :cached_latest_blood_pressures, materialized: true
  end
end
