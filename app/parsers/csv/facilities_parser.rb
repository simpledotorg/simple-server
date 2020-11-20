class Csv::FacilitiesParser
  CSV::Converters[:strip_whitespace] = ->(value) {
    begin
      value.strip
    rescue
      value
    end
  }

  CONVERTORS = [:strip_whitespace]
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
    # validate
    facilities
  end

  private

  attr_reader :file_contents, :errors
  attr_accessor :facilities

  def parse
    CSV.parse(file_contents, headers: HEADERS, converters: CONVERTORS) do |row|
      facility = extract_facility(row)
      next if facility.values.all?(&:blank?)
      facilities << Facility.new(attach_meta(facility))
    end
  end

  def validate
    facilities.each do |facility|

      errors << CSV::FacilityValidator.validate(facility).errors
    end
  end

  def extract_facility(row)
    COLUMNS.map { |attr, col_name| [attr, row[col_name]] }.to_h
  end

  def attach_meta(facility_attrs)
    facility_group = facility_group(facility_attrs)

    facility_attrs.merge(
      country: Region.root.name,
      enable_diabetes_management: facility_attrs[:enable_diabetes_management] || false,
      enable_teleconsultation: facility_attrs[:enable_teleconsultation] || false,
      facility_group_id: facility_group&.id,
    ).merge(state(facility_group))
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

  # This method can be removed and state can be inlined in the metadata once the feature-flag is deprecated
  def state(facility_group)
    if Flipper.enabled?(:regions_prep)
      {
        state: facility_group&.region.state_region.name
      }
    else
      {}
    end
  end
end
