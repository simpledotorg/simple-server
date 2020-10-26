class ImportBlocksToRegions
  include Memery

  ORG_TO_CANONICAL_ZONES_FILES = {
    "IHCI" => "config/data/india/ihci/canonical_zones.yml"
  }

  def self.import(*args)
    new(*args).import
  end

  def initialize(organization_name, dry_run: true, verbose: true)
    @organization_name = organization_name
    @dry_run = dry_run
    @verbose = verbose
  end

  attr_reader :organization_name, :dry_run, :verbose

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
    RegionType.find_by!(name: "Block")
  end

  memoize def district_region_type
    RegionType.find_by!(name: "District")
  end

  def find_or_create_region(name:, type:, parent:)
    region = Region.find_by(name: name, type: type)
    log "#{type.name} #{name} to be created under #{parent.name}" unless region

    return Region.new(name: name, type: type) if dry_run
    region || create_region_from(name: name, type: type, parent: parent)
  end

  def create_region_from(name:, type:, parent:)
    region = Region.new(name: name, type: type)
    region.path = [parent.path, region.name_to_path_label].compact.join(".")
    region.save!
    region
  end

  def log(message)
    puts message if verbose
  end
end
