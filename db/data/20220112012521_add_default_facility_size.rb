class AddDefaultFacilitySize < ActiveRecord::Migration[5.2]
  def up
    Facility.where(facility_size: nil).update_all(facility_size: :community)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
