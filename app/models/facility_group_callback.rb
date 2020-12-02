class FacilityGroupCallback

  def after_create(record)
    return unless Flipper.enabled?(:regions_prep)
    return if record.region&.persisted?

    record.create_region!(
      name: record.name,
      reparent_to: record.state_region,
      region_type: Region.region_types[:district]
    )
  end

  def after_update(record)
    return unless Flipper.enabled?(:regions_prep)
    record.region.reparent_to = record.state_region
    record.region.name = record.name
    record.region.save!
  end

end