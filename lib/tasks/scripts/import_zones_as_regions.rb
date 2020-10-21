class ImportZonesAsRegions
  include Memery

  ORG_TO_CANONICAL_ZONES_FILES = {
    "IHCI" => "config/data/india/ihci/canonical_zones.yml"
  }

  def self.import(*args)
    new(*args).import
  end

  def initialize(organization_name, dry_run: true)
    @organization_name = organization_name
    @dry_run = dry_run
  end

  attr_reader :organization_name, :dry_run

  def import
    canonical_zones = YAML.load_file(ORG_TO_CANONICAL_ZONES_FILES[organization_name])

    canonical_zones.map do |district, zones|
      district_region = find_or_create_region(name: district,
                                              type: district_region_type,
                                              parent: organization_region)
      zones.map do |zone|
        find_or_create_region(name: zone,
                              type: zone_region_type,
                              parent: district_region)
      end
    end
  end

  private

  memoize def organization_region
    Region.find_by!(name: organization_name, type: RegionType.find_by!(name: "Organization"))
  end

  memoize def zone_region_type
    RegionType.find_by!(name: "Zone")
  end

  memoize def district_region_type
    RegionType.find_by!(name: "District")
  end

  def find_or_create_region(name:, type:, parent:)
    Rails.logger.info "Create #{type.name} #{name} under #{parent.name}"
    return Region.new(name: name, type: type) if dry_run

    Region.find_by(name: name, type: type) ||
      create_region_from(name: name, type: type, parent: parent)
  end

  def create_region_from(name:, type:, parent:)
    region = Region.new(name: name, type: type)
    region.path = [parent.path, region.name_to_path_label].compact.join(".")
    region.save!
    region
  end
end
