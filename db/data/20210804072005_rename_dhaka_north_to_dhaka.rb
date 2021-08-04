class RenameDhakaNorthToDhaka < ActiveRecord::Migration[5.2]
  def up
    Region.state_regions.find_by(name: "Dhaka North").update!(name: "Dhaka")
    Facility.where(state: "Dhaka North").update_all(state: "Dhaka")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
