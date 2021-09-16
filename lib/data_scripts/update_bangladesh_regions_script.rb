class UpdateBangladeshRegionsScript < DataScript
  attr_reader :cache
  attr_reader :logger
  attr_reader :results
  DEFAULT_CSV_PATH = Rails.root.join("db", "bd_regions.csv")

  def self.call(*args)
    new(*args).call
  end

  def initialize(dry_run: true, csv_path: DEFAULT_CSV_PATH)
    super(dry_run: dry_run)

    fields = {module: :data_script, class: self.class}
    @logger = Rails.logger.child(fields)
    @results = Hash.new(0)
    @results[:dry_run] = dry_run?
    @csv_path = csv_path
    @cache = {state: {}, district: {}, block: {}, facility: {}}
  end

  def call
    return unless CountryConfig.current_country?("Bangladesh")
    destroy_empty_facilities
    create_facilities
  end

  def create_facilities
    org_region = Region.organization_regions.find_by!(slug: "nhf")
    each_row do |row|
      next if row[:division].blank? || row[:division] == "Division" || row[:facility_name].blank?
      facility_name = row[:facility_name]
      division = row[:division]
      district = row[:district]
      upazila_name = row[:upazila]
      facility_size = case row[:facility_type]
        when "CC", "USC" then "community"
        when "UHC" then "large"
        else raise ArgumentError, "unknown facility_type #{row[:facility_type]}"
      end
      logger.debug { "processing #{row[:facility_name]}" }

      division_region = find_or_create_region(:state, division, org_region)
      district_region = find_or_create_region(:district, district, division_region)
      upazila_region = find_or_create_region(:block, upazila_name, district_region)
      facility_region = find_or_create_region(:facility, facility_name, upazila_region)
      facility = Facility.new(name: facility_name, region: facility_region, facility_size: facility_size, zone: upazila_region.name, district: district_region.name, country: "Bangladesh")
      if run_safely { facility.save }
        results[:facility_creates] += 1
      else
        results[:facility_errors] += 1
      end
    end

    results
  end

  def find_or_create_region(region_type, name, parent)
    cache[region_type][name] ||= Region.find_by(name: name) || create_region(region_type, name, parent)
  end

  def create_region(region_type, name, parent)
    region = Region.new(name: name, region_type: region_type, reparent_to: parent)
    if run_safely { region.save }
      results[:region_creates] += 1
    else
      results[:region_errors] += 1
    end
    region
  end

  def destroy_empty_facilities
    sql = <<-SQL
      NOT EXISTS (SELECT 1 FROM patients where patients.registration_facility_id = facilities.id) AND
      NOT EXISTS (SELECT 1 FROM patients where patients.assigned_facility_id = facilities.id)
    SQL
    facilities = Facility.where(facility_size: ["community", nil]).where(sql)
    facilities.each do |facility|
      if run_safely { facility.destroy }
        results[:facilities_deleted] += 1
      end
    end
  end

  def run_safely
    return true if dry_run?
    yield
  end

  CONVERTERS = lambda { |field, _|
    begin
      field.try(:strip)
    rescue
      nil
    end
  }

  def each_row
    CSV.foreach(@csv_path, headers: true, header_converters: :symbol, converters: [CONVERTERS]).with_index do |row, i|
      yield row, i
    end
  end
end
