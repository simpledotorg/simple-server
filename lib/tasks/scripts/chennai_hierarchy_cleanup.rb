class ChennaiHierarchyCleanup
  def self.run
    raise "Cannot run this outside India production" unless CountryConfig.current[:name] == "India" && SimpleServer.env.production?

    state = Region.state_regions.find_by_name("Tamil Nadu")
    new_district = Region.find_by_name("Chennai")
    raise "Create Chennai district before running" if new_district.blank?

    old_districts = state.district_regions.where.not(name: new_district.name)

    ActiveRecord::Base.transaction do
      state.block_regions.each do |block|
        block.reparent_to = new_district
        block.save!
      end

      state.facilities.update_all(facility_group_id: new_district.source.id)

      FacilityGroup.where(id: old_districts.pluck(:source_id)).discard_all
    end
  end
end
