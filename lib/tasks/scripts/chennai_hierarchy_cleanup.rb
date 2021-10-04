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
    accesses = Access.where(resource_id: @old_districts.pluck(:source_id))
    user_ids_with_access = accesses.pluck(:user_id).uniq

    user_ids_with_access.each do |user_id|
      Access.create!(user_id: user_id, resource_type: "FacilityGroup", resource_id: @new_district.source_id)
    end

    accesses.discard_all
  end

  def discard_old_fgs
    raise "Old facility groups still have facilities" if FacilityGroup.where(id: @old_districts.pluck(:source_id)).map(&:facilities).any? { |facilities| facilities.count > 0 }

    FacilityGroup.where(id: @old_districts.pluck(:source_id)).discard_all
  end
end
