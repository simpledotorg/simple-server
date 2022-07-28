class MoveAndhraFacilitiesIhciScript < DataScript
  NEW_HIERARCHY = {
    "Alluri Sitharama Raju" => %w[Paderu],
    "Anakapalli" => %w[Anakapalli Narsipatnam],
    "Eluru" => %w[Nuzividu Eluru],
    "Krishna" => %w[Gudivada Machilipatnam Vuyyuru],
    "NTR" => %w[Nandigama Tiruvuru Vijayawada],
    "Visakhapatnam" => %w[Visakhapatnam GVMC Bheemunipatnam]
  }

  attr_reader :andhra
  attr_reader :csv

  def self.call(*args)
    new(*args).call
  end

  def initialize
    @andhra = Region.state_regions.find_by(slug: "andhra-pradesh")
    @csv = CSV.read("config/data/india/move_andhra_facilities_to_districts.csv", headers: true)
  end

  def call
    return unless CountryConfig.current_country?("India") && SimpleServer.env.production?
    exit_if_missing_data
    reparent_facilities

    puts "These blocks need to be deleted from dashboard:", empty_blocks
  end

  def reparent_facilities
    districts_by_name =
      FacilityGroup
        .where(id: andhra.district_regions.pluck(:source_id))
        .to_h { |fg| [fg.name, fg] }

    csv.each do |row|
      Facility.find_by(id: row["facility_id"]) do |facility|
        reparent_facility(facility, districts_by_name[row["district"]], row["block"])
      end
    end
  end

  def reparent_facility(facility, facility_group, block_name)
    facility.update!(
      district: facility_group.name,
      block: block_name,
      facility_group_id: facility_group.id
    )
  end

  def exit_if_missing_data
    raise "Missing state andhra pradesh" unless andhra.present?

    new_district_names = NEW_HIERARCHY.keys
    districts = andhra.district_regions.where(name: new_district_names)
    if districts.pluck(:name).to_set != new_district_names.to_set
      raise "Missing district. Found districts #{districts} instead of #{new_district_names}"
    end

    NEW_HIERARCHY.map do |district_name, block_names|
      blocks = andhra.district_regions.find_by(name: district_name).block_regions.where(name: block_names)
      if blocks.pluck(:name).to_set != block_names.to_set
        raise "Missing blocks. Found #{blocks} instead of #{block_names} in #{district_name}"
      end
    end

    facility_ids = csv.pluck("facility_id")
    if Facility.where(id: facility_ids).pluck(:id).to_set != facility_ids.to_set
      raise "Missing facilities"
    end
  end

  def empty_blocks
    andhra.block_regions
      .reload
      .select { |block| block.facilities.any? }
      .map { |block| "#{block.name} in #{block.district_region.name}" }
  end
end
