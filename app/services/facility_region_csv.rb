class FacilityRegionCsv
  include Memery

  HEADERS = {
    state: :state_region,
    district: :district_region,
    block: :block_region,
    facility_code: :facility_code,
    facility_name: :name,
    facility_type: :facility_type
  }

  def self.localize_header(header)
    return header unless Region.region_types.include?(header)
    header = header == :block ? :zone : header # our I18n keys still use zone for block region type
    I18n.t("helpers.label.facility.#{header}", default: header.to_s).gsub(" *", "")
  end

  def self.headers
    HEADERS.keys.map { |k| localize_header(k).to_s.humanize }
  end

  def self.to_csv(facilities)
    regions = facilities.map { |facility| FacilityRegionCsv.new(facility.region) }.sort_by { |region| [region.state_region, region.district_region, region.block_region] }
    CSV.generate(headers: true) do |csv|
      csv << headers

      regions.each do |region|
        values = HEADERS.values.map { |v| region.public_send(v) }
        csv << values
      end
    end
  end

  attr_reader :region
  attr_reader :state_region, :district_region, :block_region, :name, :facility_code, :facility_type

  def initialize(region)
    @region = region
    @state_region = region.state_region.name
    @district_region = region.district_region.name
    @block_region = region.block_region.name
    @name = region.name
    @facility_type = region.source.facility_type
    @facility_code = region.source.business_identifiers.first { |i| i.identifier_type == "dhis2_org_unit_id" }&.identifier
  end
end
