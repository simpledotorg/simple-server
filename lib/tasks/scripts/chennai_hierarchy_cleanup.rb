class ChennaiHierarchyCleanup
  OLD_DISTRICT_IDS =
    %w[75e586ec-e008-4d13-8abb-67cf83303b89
      5d9ed1b4-0f02-42a1-b36f-5b348314e35a
      e311ecca-ead9-4b9c-a113-36abbd62ccc6
      7bd9bdd4-7dde-45c2-bd75-9f512f314ef3
      4a636c16-51c3-4d38-85f7-17f009f93c7d
      32d51c45-fd3e-4dda-b612-33955e78ac06
      24f25a7a-b5be-48e0-af22-81d6c7434159
      bbf55481-3225-4868-944d-243dac655bef
      8e4fd204-7cb6-4922-89e5-23c8bbd98129
      4351ee87-37a8-471e-9c24-e63c1c6fbb07
      4c0af78f-8975-4b7e-a70f-48c93f63c5c7
      7cf12cb8-5333-4cfb-b52d-7746eb2a4cd4
      233f85a2-ddc7-414e-8ad1-e6e8a70eba05
      036031cb-718b-4c54-8413-4d40f1c59a5f
      ff816bac-12e1-4fa3-b5e1-c32291442549]

  def self.call
    raise "Cannot run this outside India production" unless CountryConfig.current[:name] == "India" && SimpleServer.env.production?

    new.call
  end

  def initialize
    @state = Region.state_regions.find_by_name("Tamil Nadu")
    @new_district = Region.find_by_name("Chennai")
    raise "Create Chennai district from dashboard before running" if @new_district.blank?

    @old_districts = @state.district_regions.where(id: OLD_DISTRICT_IDS)
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
