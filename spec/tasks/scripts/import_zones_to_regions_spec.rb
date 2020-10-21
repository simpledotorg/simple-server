require "rails_helper"
require "tasks/scripts/import_zones_to_regions"

RSpec.describe ImportZonesToRegions do
  let!(:org) { create(:organization, name: "Test Organization") }

  before do
    create(:facility, facility_group: create(:facility_group, organization: org), district: "Existing District")

    allow(CountryConfig).to receive(:current).and_return({name: "India"})
    RegionBackfill.call(dry_run: false)

    stub_const("ImportZonesToRegions::ORG_TO_CANONICAL_ZONES_FILES",
      {org.name => "spec/fixtures/files/canonical_zones_test.yml"})
  end

  it "imports zones into the districts" do
    described_class.import(org.name, dry_run: false, verbose: false)

    expect(Region.find_by_name("District 1")).to be_present
    expect(Region.find_by_name("Block 1").parent).to eq(Region.find_by_name("District 1"))
    expect(Region.find_by_name("Block 2").parent).to eq(Region.find_by_name("District 1"))
    expect(Region.find_by_name("Block 3").parent).to eq(Region.find_by_name("District 1"))
    expect(Region.find_by_name("Block a").parent).to eq(Region.find_by_name("Existing District"))
  end
end
