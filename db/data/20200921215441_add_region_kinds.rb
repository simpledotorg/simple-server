class AddRegionKinds < ActiveRecord::Migration[5.2]
  def up
    instance = RegionKind.create! name: "Instance", path: "Instance"
    org = RegionKind.create! name: "Organization", parent: instance
    facility_group = RegionKind.create! name: "FacilityGroup", parent: org
    block = RegionKind.create! name: "Block", parent: facility_group
    _facility = RegionKind.create! name: "Facility", parent: block
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
