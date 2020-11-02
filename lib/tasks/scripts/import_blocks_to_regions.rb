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
                                              region_type: "district",
                                              parent: organization_region)
      zones.map do |zone|
        find_or_create_region(name: zone,
                              region_type: "block",
                              parent: district_region)
      end
    end
  end

  private

  memoize def organization_region
    Region.find_by!(name: organization_name, region_type: "organization")
  end

  def find_or_create_region(name:, region_type:, parent:)
    region = Region.find_by(name: name, region_type: region_type)
    log "#{region_type} #{name} to be created under #{parent.name}" unless region

    return Region.new(name: name, region_type: region_type) if dry_run
    region || create_region_from(name: name, region_type: region_type, parent: parent)
  end

  def create_region_from(name:, region_type:, parent:)
    region = Region.new(name: name, region_type: region_type)
    region.path = [parent.path, region.path_label].compact.join(".")
    region.save!
    region
  end

  def log(message)
    puts message if verbose
  end
end
