class ManageDistrictRegionService
  def self.update_blocks(district_region:, new_blocks: [], remove_blocks: [])
    create_blocks(district_region, new_blocks)
    destroy_blocks(remove_blocks)
  end

  private

  class << self
    def create_blocks(district_region, block_names)
      return true if block_names.blank?

      block_names.map { |name|
        Region.create!(
          name: name,
          region_type: Region.region_types[:block],
          reparent_to: district_region
        )
      }
    end

    def destroy_blocks(block_ids)
      return true if block_ids.blank?

      block_ids.map { |id|
        Region.destroy(id) if Region.find(id) && Region.find(id).children.empty?
      }
    end
  end
end
