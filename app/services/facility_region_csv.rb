class FacilityRegionCsv
  include Memery
  attr_reader :region

  HEADERS = {
    division: :state_region,
    district: :district_region,
    upazila: :block_region,
    facility_code: :dhis2_identifer,
    facility_name: :name,
    facility_type: :facility_type
  }

  def self.to_csv(facilities)
    regions = facilities.map { |facility| FacilityRegionCsv.new(facility.region) }.sort_by { |region| [region.state_region, region.district_region, region.block_region]}
    CSV.generate(headers: true) do |csv|
      csv << HEADERS.keys.map(&:to_s).map(&:humanize)

      regions.each do |region|
        values = HEADERS.values.map { |v| region.public_send(v)}
        csv << values
      end
    end
  end

  def initialize(region)
    @region = region
  end
  memoize def state_region
    region.state_region.name
  end
  memoize def district_region
    region.district_region.name
  end
  memoize def block_region
    region.block_region.name
  end
  memoize def name
    region.name
  end
  memoize def facility_type
    region.source.facility_type
  end
  memoize def dhis2_identifer
    region.source.business_identifiers.first { |i| i.identifier_type == "dhis2_org_unit_id" }&.identifier
  end
end
