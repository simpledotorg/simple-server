class SplitBathindaAndMansa
  def self.call(*args)
    return "Cannot run this outside India" unless CountryConfig.current[:name] == "India"

    new.call
  end

  def initialize
    @bathinda_and_mansa = FacilityGroup.find_by!(name: "Bathinda and Mansa")

    # These facility groups need to be created before running this rake task
    @bathinda = FacilityGroup.find_by!(name: "Bathinda")
    @mansa = FacilityGroup.find_by!(name: "Mansa")
  end

  def call
    ActiveRecord::Base.transaction do
      create_accesses
      create_bathinda
      create_mansa
      delete_bathinda_and_mansa
    end
  end

  def create_accesses
    Access.where(resource_id: @bathinda_and_mansa.id).each do |access|
      Access.create!(access.slice(:resource_type, :user_id).merge(resource_id: @bathinda.id))
      Access.create!(access.slice(:resource_type, :user_id).merge(resource_id: @mansa.id))
      access.discard
    end
  end

  def create_bathinda
    bathinda_facilities = @bathinda_and_mansa.facilities.where(district: "Bathinda")
    bathinda_facilities.each { |facility| facility.update!(facility_group_id: @bathinda.id) }

    bathinda_facility_regions = bathinda_facilities.map(&:region)
    bathinda_block_regions = bathinda_facility_regions.map(&:block_region).uniq
    bathinda_block_regions.each do |block|
      block.reparent_to = @bathinda.region
      block.save!
    end
  end

  def create_mansa
    mansa_facilities = @bathinda_and_mansa.facilities.where(district: "Mansa")
    mansa_facilities.each { |facility| facility.update!(facility_group_id: @mansa.id) }

    mansa_facility_regions = mansa_facilities.map(&:region)
    mansa_block_regions = mansa_facility_regions.map(&:block_region).uniq
    mansa_block_regions.each do |block|
      block.reparent_to = @mansa.region
      block.save!
    end
  end

  def delete_bathinda_and_mansa
    raise "Bathinda and Mansa still has #{@bathinda_and_mansa.reload.facilities.count} facilities" if @bathinda_and_mansa.facilities.count > 0
    rails "Bathinda and Mansa still has #{@bathinda_and_mansa.reload.region.facility_regions.count} facility regions" if @bathinda_and_mansa.region.facility_regions.count > 0
    rails "Bathinda and Mansa still has #{@bathinda_and_mansa.reload.region.block_regions.count} block regions" if @bathinda_and_mansa.region.block_regions.count > 0
    @bathinda_and_mansa.discard
  end
end
