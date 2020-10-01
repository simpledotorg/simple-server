require "rails_helper"

RSpec.describe RegionKind, type: :model do
  it "createing with a parent automatically sets the path" do
    test_root = RegionKind.create! name: "TestRoot", path: "TestRoot"
    sub_kind = RegionKind.create! name: "SubKind", parent: test_root
    expect(sub_kind.path).to eq("TestRoot.SubKind")
  end
end
