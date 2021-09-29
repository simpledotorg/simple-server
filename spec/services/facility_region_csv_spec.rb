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
end