# This object keeps Facility Group in sync with related regions
#
# These callbacks are medium-term temporary.
# This class and the Region callbacks should ideally be totally superseded by the Region class.
# Keep the callbacks simple (avoid branching and optimization), idempotent (if possible) and loud when things break.
class FacilityGroupRegionSync < SimpleDelegator
  def after_create
    return if region&.persisted?

    create_region!(
      name: name,
      reparent_to: state_region,
      region_type: Region.region_types[:district]
    )
  end

  def after_update
    region.reparent_to = state_region
    region.name = name
    region.save!
  end

  def sync_block_regions
    create_block_regions
    remove_block_regions
  end

  private

  def create_block_regions
    return if new_block_names.blank?

    new_block_names.uniq.map { |name|
      Region.block_regions.create!(name: name, reparent_to: region)
    }
  end

  def remove_block_regions
    return if remove_block_ids.blank?

    block_regions = Region.where(id: remove_block_ids)
    block_regions.reject { |r| r.children.any? }.each { |region| region.destroy! }
  end
end
