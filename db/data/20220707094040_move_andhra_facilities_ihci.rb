class MoveAndhraFacilitiesIhci < ActiveRecord::Migration[5.2]
  def up
    # return unless CountryConfig.current_country?("India") && SimpleServer.env.production?

    facility_list = CSV.read("move_andhra_districts.csv").drop(1)

    # facility_names = facility_list.map(&:first)
    # return "Facilities missing" unless Facility.where(name: facility_names).pluck(:name).to_set == facility_names.to_set
    #
    # districts = facility_list.map(&:second).uniq
    # return "Districts missing" unless FacilityGroup.where(name: districts).pluck(:name).to_set == districts.to_set
    #
    # blocks = facility_list.map(&:third).uniq
    # andhra = Region.state_regions.find_by(slug: "andhra-pradesh")
    # return "Blocks missing" unless andhra.block_regions.where(name: blocks).to_set == blocks.to_set

    facility_list.each do |facility_name, district, block|
      Facility.where(name: facility_name).each do |facility|
        facility.update!(
          district: district,
          block: block,
          facility_group_id: FacilityGroup.find_by(name: district).id
        )
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
