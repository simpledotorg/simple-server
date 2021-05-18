class CreateBloodPressuresOverTime < ActiveRecord::Migration[5.2]
  def change
    create_view :blood_pressures_over_time, materialized: true
  end
end