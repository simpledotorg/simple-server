class RefreshRegionNames
  def self.call
    abort "Cannot run in production!" if SimpleServer.env.production?

    ActiveRecord::Base.transaction do
      # States
      states = Region.state_regions;
      new_state_names = Seed::FakeNames.instance.states.sample(states.count);

      states.zip(new_state_names).each do |state, new_name|
        state.slug = nil
        state.reparent_to = state.organization_region
        state.update!(name: new_name)
      end;

      # Districts
      districts = Region.district_regions;
      new_district_names = Seed::FakeNames.instance.districts.sample(districts.count);

      districts.zip(new_district_names).each do |district, new_name|
        district.slug = nil
        district.reparent_to = district.state_region
        district.update!(name: new_name)
        district.source.update!(name: new_name)
      end;

      # Blocks
      blocks = Region.block_regions;
      new_block_names = Seed::FakeNames.instance.blocks.sample(blocks.count);

      blocks.zip(new_block_names).each do |block, new_name|
        block.slug = nil
        block.reparent_to = block.district_region
        block.update!(name: new_name)
      end;

      # Facilities
      facilities = Region.facility_regions;

      facilities.each do |facility|
        village = Seed::FakeNames.instance.village
        facility.slug = nil
        facility.reparent_to = facility.block_region
        facility.update!(name: "#{facility.source.facility_type} #{village}")
        facility.source.update!(
          village_or_colony: village,
          name: "#{facility.source.facility_type} #{village}",
          zone: facility.block_region.name
        )
      end;
    end

    Rails.cache.clear
    RefreshReportingViews.call
  end
end
