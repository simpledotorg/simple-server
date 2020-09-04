class DropDailyBpMatview < ActiveRecord::Migration[5.2]
  def change
    drop_view :latest_blood_pressures_per_patient_per_days, revert_to_version: 2, materialized: 2
  end
end
