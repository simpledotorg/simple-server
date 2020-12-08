class RegionsIntegrityCheck
  SENTRY_ERROR_TITLE = "Regions Integrity Failure"

  attr_reader :inconsistencies

  def self.sweep
    new.sweep
  end

  def initialize
    @inconsistencies = {
      organizations: {},
      states: {},
      districts: {},
      blocks: {},
      facilities: {}
    }
  end

  def sweep
    add_inconsistencies(:organizations, :missing_regions, organizations[:missing_regions])
    add_inconsistencies(:organizations, :duplicate_regions, organizations[:duplicate_regions])

    add_inconsistencies(:states, :missing_regions, states[:missing_regions])
    add_inconsistencies(:states, :duplicate_regions, states[:duplicate_regions])

    add_inconsistencies(:districts, :missing_regions, districts[:missing_regions])
    add_inconsistencies(:districts, :duplicate_regions, districts[:duplicate_regions])

    add_inconsistencies(:blocks, :missing_regions, blocks[:missing_regions])
    add_inconsistencies(:blocks, :duplicate_regions, blocks[:duplicate_regions])

    add_inconsistencies(:facilities, :missing_regions, facilities[:missing_regions])
    add_inconsistencies(:facilities, :duplicate_regions, facilities[:duplicate_regions])

    report_inconsistencies
    self
  end

  private

  def organizations
    missing_regions =
      (Organization.pluck(:id).to_set -
        Region.organization_regions.pluck(:source_id).to_set
      ).to_a
    duplicate_regions =
      Region
        .organization_regions
        .group(:source_id)
        .having("count(source_id) > 1")
        .count
        .keys
        .yield_self { |src_ids| Region.organization_regions.where(source_id: src_ids).pluck(:id) }

    {
      missing_regions: missing_regions,
      duplicate_regions: duplicate_regions
    }
  end

  def states
    missing_regions =
      (Facility
         .includes(facility_group: :organization)
         .map { |f| [f.state, f.facility_group.organization.id] }
         .to_set -
        Region
          .state_regions
          .joins("inner join regions org ON org.path @> regions.path and org.region_type = 'organization'")
          .pluck("regions.name, org.source_id")
          .to_set
      ).to_a
    duplicate_regions =
      Region
        .state_regions
        .select("SUBPATH(path,0,2) AS organization_path, name, count('name')")
        .group("organization_path, name")
        .having("count('name') > 1")
        .flat_map { |r|
          Region
            .organization_regions
            .find_by_path(r.organization_path)
            .children
            .where(name: r.name)
            .pluck(:id)
        }.uniq

    {
      missing_regions: missing_regions,
      duplicate_regions: duplicate_regions
    }
  end

  def districts
    missing_regions =
      (FacilityGroup.pluck(:id).to_set -
        Region.district_regions.pluck(:source_id).to_set
      ).to_a
    duplicate_regions =
      Region
        .district_regions
        .group(:source_id)
        .having("count(source_id) > 1")
        .count
        .keys
        .yield_self { |src_ids| Region.district_regions.where(source_id: src_ids).pluck(:id) }
        .uniq

    {
      missing_regions: missing_regions,
      duplicate_regions: duplicate_regions
    }
  end

  def blocks
    missing_regions =
      (Facility.pluck(:block, :facility_group_id).to_set -
        Region
          .block_regions
          .joins("inner join regions district ON district.path @> regions.path and district.region_type = 'district'")
          .pluck("regions.name, district.source_id")
          .to_set
      ).to_a
    duplicate_regions =
      Region
        .block_regions
        .select("SUBPATH(path,0,4) AS district_path, name, count('name')")
        .group("district_path, name")
        .having("count('name') > 1")
        .flat_map { |r|
          Region
            .district_regions
            .find_by_path(r.district_path)
            .children
            .where(name: r.name)
            .pluck(:id)
        }.uniq

    {
      missing_regions: missing_regions,
      duplicate_regions: duplicate_regions
    }
  end

  def facilities
    missing_regions =
      (Facility.pluck(:id).to_set -
        Region.facility_regions.pluck(:source_id).to_set
      ).to_a
    duplicate_regions =
      Region
        .facility_regions
        .group(:source_id)
        .having("count(source_id) > 1")
        .count
        .keys
        .yield_self { |src_ids| Region.facility_regions.where(source_id: src_ids).pluck(:id) }
        .uniq

    {
      missing_regions: missing_regions,
      duplicate_regions: duplicate_regions
    }
  end

  def add_inconsistencies(resource, property, result)
    log(:info, "Sweeping #{resource} for #{property}")
    return unless result.present?
    @inconsistencies[resource][property] = result
  end

  def report_inconsistencies
    @inconsistencies.each do |resource, inconsistencies|
      next if inconsistencies.blank?

      inconsistencies.each do |_name, result|
        next if result.blank?

        data = {
          resource: resource,
          result: inconsistencies
        }

        log(:error, data)
        sentry(data)
      end
    end
  end

  def log(type, *args)
    Rails.logger.public_send(type, msg: args, class: self.class.name)
  end

  def sentry(*args)
    Raven.capture_message(SENTRY_ERROR_TITLE, logger: "logger", extra: args, tags: {type: "regions"})
  end
end
