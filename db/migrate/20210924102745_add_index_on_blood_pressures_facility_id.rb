class AddIndexOnBloodPressuresFacilityId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :blood_pressures, [:facility_id], name: :index_blood_pressures_on_facility_id, algorithm: :concurrently
  end
end
