class AssociateFacilityWithBloodPressure < ActiveRecord::Migration[5.1]
  def change
    add_column :blood_pressures, :facility_id, :uuid, null: false
  end
end
