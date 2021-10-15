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

    @logger = Rails.logger.child(module: :data_script, class: self.class.to_s)
    @results = {created: Hash.new(0), updates: Hash.new(0), deleted: Hash.new(0), errors: Hash.new(0), dry_run: dry_run?}
    @csv_path = csv_path
    @cache = {state: {}, district: {}, block: {}, facility: {}}
    unless CountryConfig.current_country?("Bangladesh")
      logger.warn("Current country is #{CountryConfig.current[:name]} - aborting!")
      abort "Error - aborting! This script only runs in Bangladesh"
    end
    @org_region = Region.organization_regions.find_by!(slug: "nhf")
    @protocol = Protocol.find_by!(name: "Bangladesh Hypertension Management Protocol for Primary Healthcare Setting")
  end

  def call
    destroy_empty_facilities
    rename_upazilas
    import_from_csv
    logger.info "Done running #{self.class} data_script - results:"
    results
  ensure
    RequestStore[:readonly] = false
  end

  private

  UPAZILA_RENAMES = {
    "Biswambarpur" => "Bishwambarpur",
    "Dakhin Surma" => "Dakshin Surma",
    "Dharmapasha" => "Dharampasha",
    "Doarabazar" => "Dowarabazar",
    "Jaintapur" => "Jaintiapur",
    "Melandah" => "Melandaha",
    "Mithamoin" => "Mithamain",
    "Taherpur" => "Tahirpur",
    "Zokiganj" => "Zakiganj"
  }

  # https://api.bd.simple.org/admin/facility_groups/jamalpur-district/facilities/uhc-melandah
  # Some Upazilas have on production have slightly different spellings in production than what is in the import CSV.
  # We need to fix the names in prod or else the import will create two upazila regions representing the same place.
  def rename_upazilas
    UPAZILA_RENAMES.each do |old_name, new_name|
      block_region = Region.block_regions.find_by(name: old_name)
      unless block_region
        results[:errors][:block_rename_missing] += 1
        next
      end
      if run_safely {
           block_region.update!(name: new_name)
           block_region.facility_regions.each { |r| r.source.update!(block: new_name) }
         }
        results[:updates][:block_rename] += 1
      else
        results[:errors][:block_rename_failed] += 1
      end
    end
  end

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
      facility_region = create_region(:facility, facility_name, upazila_region)

      facility_attrs = {
        country: "Bangladesh",
        business_identifiers: [FacilityBusinessIdentifier.new(identifier_type: :dhis2_org_unit_id, identifier: row[:facilityorganization_code])],
        district: district_region.name,
        facility_group: facility_group,
        facility_size: facility_size,
        facility_type: row[:facility_type],
        name: facility_name,
        region: facility_region,
        state: division_region.name,
        zone: upazila_region.name
      }
      facility = facility_group.facilities.build(facility_attrs)
      if run_safely { facility.save }
        results[:created][:facilities] += 1
      else
        logger.error(errors: facility.errors, msg: "Errors trying to save facility #{facility.name}")
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
        logger.error(errors: facility_group.errors, msg: "Error trying to create facility group #{facility_group.name}")
        results[:errors][:facility_groups] += 1
      end
    end
    facility_group
  end

  def find_or_create_region(region_type, name, parent)
    logger.debug(msg: "find_or_create_region #{region_type} #{name}", parent: parent)
    parent.children.find_by(name: name) || create_region(region_type, name, parent)
  end

  def create_region(region_type, name, parent)
    region = Region.new(name: name, region_type: region_type, reparent_to: parent)
    if run_safely { region.save }
      results[:created]["#{region_type}_regions".intern] += 1
    else
      logger.error("Error creating #{region_type} region #{name}", errors: region.errors)
      results[:errors][:regions] += 1
    end
    region
  end

  def empty_facilities
    sql = <<-SQL
      NOT EXISTS (SELECT 1 FROM patients where patients.registration_facility_id = facilities.id) AND
      NOT EXISTS (SELECT 1 FROM patients where patients.assigned_facility_id = facilities.id)
    SQL
    Facility.where(facility_size: ["community", nil]).includes(:facility_group, :users).where(sql)
  end

  def destroy_empty_facilities
    related_facility_groups, related_users = [], []
    facilities = empty_facilities
    logger.info { "Removing #{facilities.size} empty facilities" }
    facilities.each do |facility|
      related_facility_groups << facility.facility_group
      related_users.concat(facility.users)
      if run_safely { facility.destroy }
        results[:deleted][:facilities] += 1
      else
        results[:errors][:facility_deletes] += 1
      end
    end
    related_users.each do |user|
      next if user.phone_number_authentications.size > 1
      if run_safely { user.destroy }
        results[:deleted][:users] += 1
      end
    end
    Region.block_regions.each do |block|
      if block.children.none?
        logger.info { "Removing block #{block.name}" }
        if run_safely { block.destroy }
          results[:deleted][:blocks] += 1
        else
          results[:errors][:block_deletes] += 1
        end
      end
    end

    logger.info { "Removing facility groups with no facilities" }
    related_facility_groups.each do |facility_group|
      if facility_group.facilities.size == 0
        logger.info { "Removing facility group #{facility_group.name}" }
        if run_safely { facility_group.destroy }
          results[:deleted][:facility_groups] += 1
        else
          results[:errors][:facility_group_deletes] += 1
        end
      end
    end
    logger.info { "There are #{empty_facilities.size} remaining empty facilities" }
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
