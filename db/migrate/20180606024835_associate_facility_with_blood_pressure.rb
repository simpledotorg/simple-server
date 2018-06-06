class AssociateFacilityWithBloodPressure < ActiveRecord::Migration[5.1]
  def change
    add_reference :blood_pressures, :facility, type: :uuid, null: false
  end
end
