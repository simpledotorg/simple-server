require "rails_helper"

RSpec.describe RegionType, type: :model do
  it "createing with a parent automatically sets the path" do
    test_root = RegionType.create! name: "TestRoot", path: "TestRoot"
    sub_kind = RegionType.create! name: "SubKind", parent: test_root
    expect(sub_kind.path).to eq("TestRoot.SubKind")
  end
end
