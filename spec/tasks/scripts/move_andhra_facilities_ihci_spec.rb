require "rails_helper"
require "tasks/scripts/move_andhra_facilities"

RSpec.describe MoveAndhraFacilitiesIhci do
  it "reparents facilities to the right block and district" do
    eluru = create(:facility_group, name: "Eluru", state: "Andhra Pradesh")

    create(:region, :block, name: "A block", reparent_to: eluru.region)
    create(:region, :block, name: "Eluru", reparent_to: eluru.region)

    facility = create(:facility, name: "HWC ARUTEEGALAPADU PHC KALIDINDI", district: "A district", block: "A block", facility_group: eluru)
    described_class.call

    facility.reload
    expect(facility.district).to eq("Eluru")
    expect(facility.block).to eq("Eluru")
    expect(facility.facility_group).to eq(eluru)
  end

  it "exits on production if all the facilities don't exist" do
    stub_const("SIMPLE_SERVER_ENV", "production")
    expect(described_class.call).to eq("Facilities missing")
  end
end
