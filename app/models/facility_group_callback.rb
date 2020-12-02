class FacilityGroupCallback
  def after_create(record)
    return true unless Flipper.enabled?(:regions_prep)
    return if record.region&.persisted?

    record.create_region!(
      name: record.name,
      reparent_to: record.state_region,
      region_type: Region.region_types[:district]
    )
  end

  def after_update(record)
    return true unless Flipper.enabled?(:regions_prep)
    record.region.reparent_to = record.state_region
    record.region.name = record.name
    record.region.save!
  end

  def sync_block_regions(record)
    return true unless Flipper.enabled?(:regions_prep)
    create_block_regions(record)
    remove_block_regions(record)
  end

  def create_block_regions(record)
    return if record.new_block_names.blank?

    record.new_block_names.map { |name|
      Region.block_regions.create!(name: name, reparent_to: record.region)
    }
  end

  def remove_block_regions(record)
    return if record.remove_block_ids.blank?

    record.remove_block_ids.map { |id|
      next unless Region.find(id)
      next unless Region.find(id).children.empty?

      Region.destroy(id)
    }
  end
end