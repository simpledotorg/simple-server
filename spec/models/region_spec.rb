require "rails_helper"

RSpec.describe Region, type: :model do
  context "validations" do
    it "requires a region type" do
      region = Region.new(name: "foo", path: "foo")
      expect(region).to_not be_valid
      expect(region.errors[:region_type]).to eq(["can't be blank"])
    end
  end

  context "slugs" do
    it "handles duplicate names nicely when creating a slug" do
      region_1 = Region.create!(name: "New York", region_type: "state", reparent_to: Region.root)
      region_2 = Region.create!(name: "New York", region_type: "district", reparent_to: region_1)
      region_3 = Region.create!(name: "New York", region_type: "block", reparent_to: region_2)
      region_4 = Region.create!(name: "New York", region_type: "facility", reparent_to: region_3)
      region_5 = Region.create!(name: "New York", region_type: "facility", reparent_to: region_3)

      expect(region_1.slug).to eq("new-york")
      expect(region_2.slug).to eq("new-york-district")
      expect(region_3.slug).to eq("new-york-block")
      expect(region_4.slug).to eq("new-york-facility")
      expect(region_5.slug).to match(/new-york-facility-[[:alnum:]]{8}$/)
    end
  end

  context "behavior" do
    it "sets a valid path" do
      enable_flag(:regions_prep)

      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, name: "District XYZ", organization: org, state: "Test State")
      facility_1 = create(:facility, name: "facility UHC (ZZZ)", state: "Test State", block: "Block22", facility_group: facility_group_1)
      long_name = ("This is a long facility name" * 10)
      facility_2 = create(:facility, name: long_name, block: "Block23", state: "Test State", facility_group: facility_group_1)

      expect(org.region.reload.path).to eq("india.test_organization")
      expect(facility_group_1.region.path).to eq("india.test_organization.test_state.#{facility_group_1.region.path_label}")
      expect(facility_1.region.path).to eq("#{facility_group_1.region.path}.#{facility_1.block.downcase}.#{facility_1.region.slug.underscore}")
      expect(facility_2.region.path).to eq("#{facility_group_1.region.path}.#{facility_2.block.downcase}.#{facility_2.region.slug[0..254].underscore}")
    end

    it "can soft delete nodes" do
      enable_flag(:regions_prep)

      org = create(:organization, name: "Test Organization")
      facility_group_1 = create(:facility_group, organization: org, state: "State 1")
      facility_group_2 = create(:facility_group, organization: org, state: "State 2")
      _facility_1 = create(:facility, name: "facility1", state: "State 1", facility_group: facility_group_1)
      _facility_2 = create(:facility, name: "facility2", state: "State 2", facility_group: facility_group_2)

      state_2 = Region.find_by!(name: "State 2")
      expect(state_2.children).to_not be_empty
      expect(facility_group_2.reload.region).to_not be_nil

      facility_group_2.discard
      # Ensure that facility group 2's region is discarded with it and no longer in the tree
      expect(facility_group_2.region.path).to be_nil
      expect(facility_group_2.region.parent).to be_nil
      expect(org.region.children.map(&:name)).to contain_exactly("State 1", "State 2")
      expect(state_2.children).to be_empty
    end
  end

  context "association helper methods" do
    it "generates the appropriate has_one or has_many type methods based on the available region types" do
      enable_flag(:regions_prep)

      facility_group_1 = create(:facility_group, organization: create(:organization), state: "State 1")
      create(:facility, facility_group: facility_group_1, state: "State 1")

      root_region = Region.root
      org_region = Region.organization_regions.first
      state_region = Region.state_regions.first
      district_region = Region.district_regions.first
      block_region = Region.block_regions.first
      facility_region = Region.facility_regions.first

      expect(root_region.root).to eq root_region
      expect(root_region.organization_regions).to contain_exactly org_region
      expect(root_region.state_regions).to contain_exactly state_region
      expect(root_region.district_regions).to contain_exactly district_region
      expect(root_region.block_regions).to contain_exactly block_region
      expect(root_region.facility_regions).to contain_exactly facility_region
      expect { root_region.roots }.to raise_error NoMethodError

      expect(org_region.root).to eq root_region
      expect(org_region.organization_region).to eq org_region
      expect(org_region.state_regions).to contain_exactly state_region
      expect(org_region.district_regions).to contain_exactly district_region
      expect(org_region.block_regions).to contain_exactly block_region
      expect(org_region.facility_regions).to contain_exactly facility_region
      expect { org_region.roots }.to raise_error NoMethodError
      expect { org_region.organization_regions }.to raise_error NoMethodError

      expect(state_region.root).to eq root_region
      expect(state_region.organization_region).to eq org_region
      expect(state_region.state_region).to eq state_region
      expect(state_region.district_regions).to contain_exactly district_region
      expect(state_region.block_regions).to contain_exactly block_region
      expect(state_region.facility_regions).to contain_exactly facility_region
      expect { state_region.roots }.to raise_error NoMethodError
      expect { state_region.organization_regions }.to raise_error NoMethodError
      expect { state_region.state_regions }.to raise_error NoMethodError

      expect(district_region.root).to eq root_region
      expect(district_region.organization_region).to eq org_region
      expect(district_region.state_region).to eq state_region
      expect(district_region.district_region).to eq district_region
      expect(district_region.block_regions).to contain_exactly block_region
      expect(district_region.facility_regions).to contain_exactly facility_region
      expect { district_region.roots }.to raise_error NoMethodError
      expect { district_region.organization_regions }.to raise_error NoMethodError
      expect { district_region.state_regions }.to raise_error NoMethodError
      expect { district_region.district_regions }.to raise_error NoMethodError

      expect(block_region.root).to eq root_region
      expect(block_region.organization_region).to eq org_region
      expect(block_region.state_region).to eq state_region
      expect(block_region.district_region).to eq district_region
      expect(block_region.block_region).to eq block_region
      expect(block_region.facility_regions).to contain_exactly facility_region
      expect { block_region.roots }.to raise_error NoMethodError
      expect { block_region.organization_regions }.to raise_error NoMethodError
      expect { block_region.state_regions }.to raise_error NoMethodError
      expect { block_region.district_regions }.to raise_error NoMethodError
      expect { block_region.block_regions }.to raise_error NoMethodError

      expect(facility_region.root).to eq root_region
      expect(facility_region.organization_region).to eq org_region
      expect(facility_region.state_region).to eq state_region
      expect(facility_region.district_region).to eq district_region
      expect(facility_region.block_region).to eq block_region
      expect(facility_region.facility_region).to eq facility_region
      expect { facility_region.roots }.to raise_error NoMethodError
      expect { facility_region.organization_regions }.to raise_error NoMethodError
      expect { facility_region.state_regions }.to raise_error NoMethodError
      expect { facility_region.district_regions }.to raise_error NoMethodError
      expect { facility_region.block_regions }.to raise_error NoMethodError
      expect { facility_region.facility_regions }.to raise_error NoMethodError
    end
  end
end
