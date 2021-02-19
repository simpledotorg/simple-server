require "rails_helper"

RSpec.describe FacilityDistrict, type: :model do
  let(:facility_group) { create(:facility_group) }
  let(:other_facility_group) { create(:facility_group) }

  let!(:bathinda_facility) { create(:facility, district: "Bathinda", facility_group: facility_group) }
  let!(:mansa_facility) { create(:facility, district: "Mansa", facility_group: facility_group) }
  let!(:other_bathinda_facility) { create(:facility, district: "Bathinda", facility_group: other_facility_group) }

  it "has a cache_key" do
    facility_district = FacilityDistrict.new(name: "Bathinda")
    expect(facility_district.cache_key).to eq("facility_districts/Bathinda")
  end

  it "has a slug" do
    facility_district = FacilityDistrict.new(name: "New York State")
    expect(facility_district.slug).to eq("new-york-state")
  end

  describe "#facilities" do
    it "returns facilities with matching district name" do
      facility_district = FacilityDistrict.new(name: "Bathinda")

      expect(facility_district.facilities).to contain_exactly(bathinda_facility, other_bathinda_facility)
    end

    it "only looks in facilities provided in the scope" do
      facility_district = FacilityDistrict.new(name: "Bathinda", scope: facility_group.facilities)

      expect(facility_district.facilities).to contain_exactly(bathinda_facility)
    end
  end

  describe "#organization" do
    it "returns the facilities' organization" do
      facility_district = FacilityDistrict.new(name: "Bathinda", scope: facility_group.facilities)

      expect(facility_district.organization).to eq(bathinda_facility.organization)
    end

    it "returns any one organization when facilities are in different organizations" do
      facility_district = FacilityDistrict.new(name: "Bathinda")

      organizations = [bathinda_facility, other_bathinda_facility].map(&:organization)

      expect(organizations).to include(facility_district.organization)
    end
  end

  describe "#model_name" do
    it "returns FacilityDistrict" do
      facility_district = FacilityDistrict.new(name: "Bathinda")

      expect(facility_district.model_name).to eq("FacilityDistrict")
    end
  end

  describe "#updated_at" do
    it "returns most recent facility updated timestamp" do
      facility_district = FacilityDistrict.new(name: "Bathinda")

      expected_timestamp = [bathinda_facility, other_bathinda_facility].map(&:updated_at).max

      expect(facility_district.updated_at).to be_within(0.001.seconds).of(expected_timestamp)
    end

    it "returns a generic timestamp if no facilities are present" do
      facility_district = FacilityDistrict.new(name: "Not A Real District")

      expected_timestamp = Time.current.beginning_of_day

      expect(facility_district.updated_at).to eq(expected_timestamp)
    end
  end
end
