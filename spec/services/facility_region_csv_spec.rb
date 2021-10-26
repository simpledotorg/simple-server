require "rails_helper"

describe FacilityRegionCsv, type: :model do
  it "outputs localized headers" do
    facilities = create_list(:facility, 3)
    I18n.with_locale(:en_IN) do
      result = described_class.to_csv(facilities)
      expect(described_class.localize_header(:state)).to eq("State")
      expect(result.lines.first).to start_with("State,District,Block,Facility")
    end
    I18n.with_locale(:en_BD) do
      result = described_class.to_csv(facilities)
      expect(described_class.localize_header(:state)).to eq("Division")
      expect(result.lines.first).to start_with("Division,District,Upazila,Facility")
    end
  end

  it "outputs facility data" do
    facilities = create_list(:facility, 3)
    result = I18n.with_locale(:en_BD) do
      described_class.to_csv(facilities)
    end
    csv = CSV.parse(result, headers: true)
    csv.each do |row|
      expect(facilities.map(&:name)).to include(row["Facility name"])
      expect(Region.block_regions.map(&:name)).to include(row["Upazila"])
    end
  end

  it "wraps a facility region to output CSV data" do
    facility_group = create(:facility_group, name: "District", state: "New York")
    facility = create(:facility, name: "CC Greenbush", state: "New York", block: "Brooklyn", facility_type: "CC", facility_group: facility_group)
    region = facility.region
    region_csv = described_class.new(region)
    expect(region_csv.state_region).to eq("New York")
    expect(region_csv.block_region).to eq("Brooklyn")
    expect(region_csv.facility_type).to eq("CC")
  end
end
