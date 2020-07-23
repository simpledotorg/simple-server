class StateRegionCreator
  def call
    Organization.find_each do |org|
      org.update! parent_region: Region.root
    end

    Facility.find_each do |facility|
      state_name = facility.state
      facility_group = facility.facility_group
      organization = facility_group.organization

      if facility_group.nil?
        puts "Missing facility_group for #{facility}"
        next
      end
      region = Region.state.find_by(name: state_name) ||
        Region.create!(name: state_name, level: :state, parent_region: organization)
      region._facility_groups << facility_group
      region.save!
    end
  end
end
