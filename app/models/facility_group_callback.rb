class FacilityGroupCallback < SimpleDelegator
  def after_create
    return true unless Flipper.enabled?(:regions_prep)
    return if region&.persisted?

    create_region!(
      name: name,
      reparent_to: state_region,
      region_type: Region.region_types[:district]
    )
  end

  def after_update
    return true unless Flipper.enabled?(:regions_prep)
    region.reparent_to = state_region
    region.name = name
    region.save!
  end

  def sync_block_regions
    return true unless Flipper.enabled?(:regions_prep)
    create_block_regions
    remove_block_regions
  end

  private

  def create_block_regions
    return if new_block_names.blank?

    new_block_names.map { |name|
      Region.block_regions.create!(name: name, reparent_to: region)
    }
  end

  def remove_block_regions
    return if remove_block_ids.blank?

    remove_block_ids.map { |id|
      next unless Region.find(id)
      next unless Region.find(id).children.empty?

      Region.destroy(id)
    }
  end
end