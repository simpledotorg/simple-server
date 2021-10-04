class ChennaiHierarchyCleanup
  def self.call
    raise "Cannot run this outside India production" unless CountryConfig.current[:name] == "India" && SimpleServer.env.production?

    new.call
  end

  def initialize
    @state = Region.state_regions.find_by_name("Tamil Nadu")
    @new_district = Region.find_by_name("Chennai")
    raise "Create Chennai district from dashboard before running" if @new_district.blank?

    @old_districts = @state.district_regions.where.not(name: @new_district.name)
  end

  def call
    ActiveRecord::Base.transaction do
      reparent_blocks
      set_fg_id_on_facilities
      copy_accesses
      discard_old_fgs
    end
  end

  def reparent_blocks
    @state.block_regions.each do |block|
      block.reparent_to = @new_district
      block.save!
    end
  end

  def set_fg_id_on_facilities
    @state.facilities.update_all(facility_group_id: @new_district.source.id)
  end

  def copy_accesses
    Access.where(resource_id: @old_districts.pluck(:source_id)).each do |access|
      Access.create!(access.slice(:resource_type, :user_id).merge(resource_id: @new_district.source_id))
      access.discard
    end
  end

  def discard_old_fgs
    # TODO: make sure facility groups are empty before deleting
    FacilityGroup.where(id: @old_districts.pluck(:source_id)).discard_all
  end
end
