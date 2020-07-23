class StateRegionCreator
  def call
    Organization.find_each do |org|
      org.update! parent_region: Region.root
    end

    Facility.find_each do |facility|
      state = facility.state
      facility_group = facility.facility_group
      if facility_group.nil?
        puts "Missing facility_group for #{facility}"
        next
      end
      region = Region.state.find_by(name: state) || Region.create(name: state, level: :state)
      region._facility_groups << facility_group
      region.parent_region = facility_group.organization
      region.save!
    end
  end
end