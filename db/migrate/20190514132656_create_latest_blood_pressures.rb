class CreateLatestBloodPressures < ActiveRecord::Migration[5.1]
  def change
    create_view :latest_blood_pressures, materialized: true
  end
end
