require "rails_helper"
require Rails.root.join("db", "data", "20220707094040_move_andhra_facilities_ihci")

RSpec.describe MoveAndhraFacilitiesIhci do
  it "works" do
    #facility_groups = ["Eluru",
    #      "Krishna",
    #      "NTR",
    #      "Anakapalli",
    #      "Alluri sitharama raju",
    #      "Visakhapatnam"].map do |district|
    #
    #     end
    
    eluru = create(:facility_group, name: "Eluru", state: "Andhra Pradesh")

    create(:region, :block, name: "A block", reparent_to: eluru.region)
    create(:region, :block, name: "Eluru", reparent_to: eluru.region)

    facility = create(:facility, name: "HWC ARUTEEGALAPADU PHC KALIDINDI", district: "A district", block: "A block", facility_group: eluru)
    described_class.new.up

    facility.reload
    expect(facility.district).to eq("Eluru")
    expect(facility.block).to eq("Eluru")
    expect(facility.facility_group).to eq(eluru)
  end
end
