require "rails_helper"
require "tasks/scripts/import_facility_block_names"

RSpec.describe ImportFacilityBlockNames do
  it "imports blocks for matching facilities and skip others" do
    create(:facility, name: "Facility 1", state: "Maharashtra", district: "Wardha")

    expect(Rails.logger).to receive(:info).with("Facility Facility 2 in Block A, district Singapore not found")
    expect(Rails.logger).to receive(:info).with("Updated 1 facilities, 1 facilities not found")
    ImportFacilityBlockNames.import("spec/fixtures/files/facility_blocks_list.csv")
  end
end
