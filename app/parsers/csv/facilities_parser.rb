class Csv::FacilitiesParser
  CSV::Converters[:strip_whitespace] = ->(value) {
    begin
      value.strip
    rescue
      value
    end
  }

  CONVERTERS = [:strip_whitespace]
  HEADERS = true
  COLUMNS = if Flipper.enabled?(:regions_prep)
    {
      organization_name: "organization",
      facility_group_name: "facility_group",
      name: "facility_name",
      facility_type: "facility_type",
      street_address: "street_address (optional)",
      village_or_colony: "village_or_colony (optional)",
      zone: "zone_or_block",
      district: "district",
      pin: "pin (optional)",
      latitude: "latitude (optional)",
      longitude: "longitude (optional)",
      facility_size: "size (optional)",
      enable_diabetes_management: "enable_diabetes_management (true/false)"
    }
  else
    {
      organization_name: "organization",
      facility_group_name: "facility_group",
      name: "facility_name",
      facility_type: "facility_type",
      street_address: "street_address (optional)",
      village_or_colony: "village_or_colony (optional)",
      zone: "zone_or_block",
      district: "district",
      state: "state",
      pin: "pin (optional)",
      latitude: "latitude (optional)",
      longitude: "longitude (optional)",
      facility_size: "size (optional)",
      enable_diabetes_management: "enable_diabetes_management (true/false)"
    }
  end

  def self.parse(*args)
    new(*args).call
  end

  def initialize(file_contents)
    @file_contents = file_contents
    @facilities = []
  end

  def call
    parse
    facilities
  end

  private

  attr_reader :file_contents
  attr_accessor :facilities

  def parse
    CSV.parse(file_contents, headers: HEADERS, converters: CONVERTERS) do |row|
      attrs = facility_attributes(row)
      next if attrs.values.all?(&:blank?)

      facilities << Facility.new(attrs)
    end
  end

  def facility_attributes(row)
    COLUMNS
      .map { |attr, col_name| [attr, row[col_name]] }
      .to_h
      .yield_self { |attrs| attrs.merge(set_region_data(attrs)) }
      .yield_self { |attrs| attrs.merge(set_state(attrs)) }
      .yield_self { |attrs| attrs.merge(set_blanks_to_false(attrs)) }
  end

  def set_region_data(facility_attrs)
    {
      country: Region.root.name,
      facility_group_id: facility_group(facility_attrs)&.id
    }
  end

  # This method can be removed and state can be inlined in the region metadata once the feature-flag is deprecated
  def set_state(facility_attrs)
    if Flipper.enabled?(:regions_prep)
      {
        state: facility_group(facility_attrs)&.region.state_region.name
      }
    else
      {}
    end
  end

  def set_blanks_to_false(facility_attrs)
    {
      enable_teleconsultation: facility_attrs[:enable_teleconsultation] || false,
      enable_diabetes_management: facility_attrs[:enable_diabetes_management] || false
    }
  end

  def organization(organization_name)
    Organization.find_by(name: organization_name)
  end

  def facility_group(facility_attrs)
    FacilityGroup.find_by(
      name: facility_attrs[:facility_group_name],
      organization: organization(facility_attrs[:organization_name])
    )
  end
end
