class UpdateBangladeshRegionsScript < DataScript
  DEFAULT_CSV_PATH = Rails.root.join("db", "bd_regions.csv").freeze

  attr_reader :cache
  attr_reader :org_region
  attr_reader :protocol
  attr_reader :results

  def self.call(*args)
    new(*args).call
  end

  def initialize(dry_run: true, csv_path: DEFAULT_CSV_PATH)
    super(dry_run: dry_run)

    fields = {module: :data_script, class: self.class.to_s}
    @logger = Rails.logger.child(fields)
    @results = {created: Hash.new(0), deleted: Hash.new(0), errors: Hash.new(0), dry_run: dry_run?}
    @csv_path = csv_path
    @cache = {state: {}, district: {}, block: {}, facility: {}}
    unless CountryConfig.current_country?("Bangladesh")
      logger.warn("Current country is #{CountryConfig.current[:name]} - aborting!")
      return
    end
    @org_region = Region.organization_regions.find_by!(slug: "nhf")
    @protocol = Protocol.find_by!(name: "Bangladesh Hypertension Management Protocol for Primary Healthcare Setting")
  end

  def call
    destroy_empty_facilities
    import_from_csv
  end

  private

  def import_from_csv
    each_row do |row|
      next if row[:division].blank? || row[:division] == "Division" || row[:facility_name].blank?
      logger.debug { "Processing #{row[:facility_name]}" }

      facility_name, division_name, district_name, upazila_name = row[:facility_name], row[:division], row[:district], row[:upazila]
      facility_size = case row[:facility_type]
        when "CC", "USC" then "community"
        when "UHC" then "large"
        else results[:errors][:unknown_facility_size] += 1
      end

      division_region = find_or_create_region(:state, division_name, org_region)
      district_region = find_or_create_region(:district, district_name, division_region)
      facility_group = find_or_create_facility_group(district_name, district_region)
      upazila_region = find_or_create_region(:block, upazila_name, district_region)
      facility_region = find_or_create_region(:facility, facility_name, upazila_region)

      facility_attrs = {
        country: "Bangladesh",
        business_identifiers: [FacilityBusinessIdentifier.new(identifier_type: :dhis2_org_unit_id, identifier: row[:facilityorganization_code])],
        district: district_region.name,
        facility_group: facility_group,
        facility_size: facility_size,
        name: facility_name,
        region: facility_region,
        state: division_region.name,
        zone: upazila_region.name
      }
      facility = Facility.new(facility_attrs)
      if run_safely { facility.save }
        results[:created][:facilities] += 1
      else
        logger.warn(errors: facility.errors, msg: "Errors trying to save facility #{facility.name}")
        results[:errors][:facilities] += 1
      end
    end

    results
  end

  def find_or_create_facility_group(district_name, district_region)
    facility_group = FacilityGroup.find_by(name: district_name) || FacilityGroup.new(name: district_name, organization: org_region.source, region: district_region, protocol: protocol, generating_seed_data: true)
    if facility_group.new_record?
      if run_safely { facility_group.save }
        results[:created][:facility_groups] += 1
      else
        logger.warn(errors: facility_group.errors, msg: "Errors trying to save facility group #{facility_group.name}")
        results[:errors][:facility_groups] += 1
      end
    end
    facility_group
  end

  def find_or_create_region(region_type, name, parent)
    cache[region_type][name] ||= Region.where(region_type: region_type).find_by(name: name) || create_region(region_type, name, parent)
  end

  def create_region(region_type, name, parent)
    region = Region.new(name: name, region_type: region_type, reparent_to: parent)
    if run_safely { region.save }
      results[:created][:regions] += 1
    else
      results[:errors][:regions] += 1
    end
    region
  end

  def destroy_empty_facilities
    sql = <<-SQL
      NOT EXISTS (SELECT 1 FROM patients where patients.registration_facility_id = facilities.id) AND
      NOT EXISTS (SELECT 1 FROM patients where patients.assigned_facility_id = facilities.id)
    SQL
    related_facility_groups = []
    related_users = []

    facilities = Facility.where(facility_size: ["community", nil]).includes(:facility_group, :users).where(sql)
    logger.info { "Removing #{facilities.size} empty facilities" }
    facilities.each do |facility|
      related_facility_groups << facility.facility_group
      related_users.concat(facility.users)
      if run_safely { facility.destroy }
        results[:deleted][:facilities] += 1
      end
    end
    related_users.each do |user|
      next if user.phone_number_authentications.size > 1
      if run_safely { user.destroy }
        results[:deleted][:users] += 1
      end
    end
    logger.info { "Removing facility groups with no facilities" }
    related_facility_groups.each do |facility_group|
      if facility_group.facilities.size == 0
        logger.info { "Removing facility group #{facility_group.name} " }
        run_safely { facility_group.destroy }
      end
    end
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
