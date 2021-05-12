module SplitBathindaAndMansa
  def self.call
    ActiveRecord::Base.transaction do
      bathinda_and_mansa = FacilityGroup.find_by!(name: "Bathinda and Mansa")

      # Create these facility groups in IHCI before running this rake task
      bathinda = FacilityGroup.find_by!(name: "Bathinda")
      mansa = FacilityGroup.find_by!(name: "Mansa")

      bathinda_facilities = bathinda_and_mansa.facilities.where(district: "Bathinda")
      bathinda_facilities.each { |facility| facility.update!(facility_group_id: bathinda.id) }

      bathinda_facility_regions = bathinda_facilities.map(&:region)
      bathinda_block_regions = bathinda_facility_regions.map(&:block_region).uniq
      bathinda_block_regions.each do |block|
        block.reparent_to = bathinda.region
        block.save!
      end

      mansa_facilities = bathinda_and_mansa.facilities.where(district: "Mansa")
      mansa_facilities.each { |facility| facility.update!(facility_group_id: mansa.id) }

      mansa_facility_regions = mansa_facilities.map(&:region)
      mansa_block_regions = mansa_facility_regions.map(&:block_region).uniq
      mansa_block_regions.each do |block|
        block.reparent_to = mansa.region
        block.save!
      end

      raise "Bathinda and Mansa still has #{bathinda_and_mansa.facilities.count} facilities" if bathinda_and_mansa.facilities.count > 0
      bathinda_and_mansa.discard
    end
  end
end
