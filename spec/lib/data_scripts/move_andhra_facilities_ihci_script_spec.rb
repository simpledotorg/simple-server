require "rails_helper"
require "data_scripts/move_andhra_facilities_ihci_script"

describe MoveAndhraFacilitiesIhciScript do
  it "reparents facilities to the right block and district" do
    eluru = create(:facility_group, name: "Eluru", state: "Andhra Pradesh")

    create(:region, :block, name: "A block", reparent_to: eluru.region)
    create(:region, :block, name: "Eluru", reparent_to: eluru.region)

    facility = create(:facility, name: "A Facility", district: "A district", block: "A block", facility_group: eluru)
    described_class.new.reparent_facility(facility, eluru, "Eluru")

    facility.reload
    expect(facility.district).to eq("Eluru")
    expect(facility.block).to eq("Eluru")
    expect(facility.facility_group).to eq(eluru)
  end

  it "exits on production if the state don't exist" do
    stub_const("SIMPLE_SERVER_ENV", "production")
    expect { described_class.call }.to raise_error("Missing state andhra pradesh")
  end
end
