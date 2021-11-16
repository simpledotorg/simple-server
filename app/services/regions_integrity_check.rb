# This is a medium-term temporary class that periodically sweeps to check if regions are in a consistent state
# It can be removed after good progress has been made around Regions work and we're confident of our work overall.
#
# Performance –
# For a production-sized database as of 8-12-2020,
#
# benchmark { RegionsIntegrityCheck.sweep }
# I, [2020-12-08T14:48:08.348171 #45463]  INFO -- : Benchmarking (1012.2ms)
# I, [2020-12-08T14:49:38.327484 #45463]  INFO -- : Benchmarking (1106.5ms)
# I, [2020-12-08T14:49:45.556005 #45463]  INFO -- : Benchmarking (967.6ms)
# I, [2020-12-08T14:49:51.610416 #45463]  INFO -- : Benchmarking (1015.1ms)
# I, [2020-12-08T14:50:00.146900 #45463]  INFO -- : Benchmarking (989.6ms)
# I, [2020-12-08T14:50:06.171613 #45463]  INFO -- : Benchmarking (1071.7ms)
# I, [2020-12-08T14:50:20.987763 #45463]  INFO -- : Benchmarking (1056.3ms)
# I, [2020-12-08T14:50:28.620415 #45463]  INFO -- : Benchmarking (1105.1ms)
#
# Reporting –
# It reports inconsistencies to Sentry and Logs to standard logger
class RegionsIntegrityCheck
  prepend SentryHandler
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

  def call
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
  alias_method :sweep, :call

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
          .joins("inner join regions org ON org.path @> regions.path and org.region_type = 'organization'") # self join with parent organization
          .pluck("regions.name, org.source_id")
          .to_set
      ).to_a
    duplicate_regions =
      Region
        .state_regions
        .select("SUBPATH(path,0,2) AS organization_path, name, count('name')") # fetch parent organization path
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
          .joins("inner join regions district ON district.path @> regions.path and district.region_type = 'district'") # self join with district organization
          .pluck("regions.name, district.source_id")
          .to_set
      ).to_a
    duplicate_regions =
      Region
        .block_regions
        .select("SUBPATH(path,0,4) AS district_path, name, count('name')") # fetch parent district path
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

  def log(type, args)
    Rails.logger.public_send(type, msg: args, class: self.class.name)
  end

  def sentry(args)
    Sentry.capture_message(SENTRY_ERROR_TITLE, extra: args, tags: {type: "regions"})
  end
end
