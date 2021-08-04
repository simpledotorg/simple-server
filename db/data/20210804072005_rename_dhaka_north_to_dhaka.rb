class RenameDhakaNorthToDhaka < ActiveRecord::Migration[5.2]
  def up
    return unless CountryConfig.current_country?("Bangladesh") && SimpleServer.env.production?

    Region.state_regions.find_by(name: "Dhaka North").update!(name: "Dhaka")
    Facility.where(state: "Dhaka North").update_all(state: "Dhaka")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
