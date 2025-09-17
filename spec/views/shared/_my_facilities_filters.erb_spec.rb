require "rails_helper"

RSpec.describe "shared/_my_facilities_filters.erb", type: :view do
  let(:organization) { create(:organization) }
  let(:organization_region) { create(:region, name: "Organization", region_type: "organization", path: "organization") }
  let(:current_period) { Period.current }
  let(:sub_region) { create(:region, name: "State Subregion", region_type: "state", path: "organization.state") }

  let(:district1) { double("FacilityGroup", id: 1, name: "District 1", slug: "district-1") }
  let(:district2) { double("FacilityGroup", id: 2, name: "District 2", slug: "district-2") }

  let(:zone1) { "zone1" }
  let(:zone2) { "zone2" }

  let(:size_small) { "small" }
  let(:size_medium) { "medium" }

  helper do
    def accessible_region?(*args)
      true
    end

    def active_action?(*args)
      false
    end

    attr_reader :current_admin

    def t(key, **args)
      if key == "region_type.block" && CountryConfig.current == "Bangladesh"
        return "upazilas"
      end
      key.to_s.titleize
    end
  end

  before do
    @current_admin = create(:admin, :manager)
    assign(:current_admin, @current_admin)

    assign(:facility_groups, [district1, district2])
    assign(:zones, [zone1, zone2])
    assign(:facility_sizes, [size_small, size_medium])
    assign(:selected_facility_group, nil)
    assign(:selected_zones, [])
    assign(:selected_facility_sizes, [])
    assign(:for_end_of_month_display, Date.today.strftime("%Y-%m-%d"))

    allow(@current_admin).to receive(:feature_enabled?).and_return(false)
    allow(view).to receive(:params).and_return({})
    allow(view).to receive(:request).and_return(double("Request", path: "/test"))
    allow(Facility).to receive(:localized_facility_size).and_return("Small", "Medium")
  end

  context "when all_district_overview Flipper flag is enabled" do
    before do
      allow(view).to receive(:access_all_districts_overview?).and_return(true)
      allow(Flipper).to receive(:enabled?).with("all_district_overview").and_return(true)
      render
    end

    it "defaults to 'All districts' for facility group" do
      expect(rendered).to include("All districts")
    end

    it "lists all districts in facility group dropdown" do
      expect(rendered).to include("District 1")
    end

    it "lists all zones in the zone dropdown" do
      expect(rendered).to include("Zone1")
      expect(rendered).to include("Zone2")
    end

    it "defaults to 'All facility sizes' for size filter" do
      expect(rendered).to include("All facility sizes")
    end

    it "lists all facility sizes in the size dropdown" do
      expect(rendered).to include("Small")
      expect(rendered).to include("Medium")
    end
  end

  context "when all_district_overview Flipper flag is disabled" do
    before do
      allow(view).to receive(:access_all_districts_overview?).and_return(false)
      allow(Flipper).to receive(:enabled?).with("all_district_overview").and_return(false)
      assign(:selected_facility_group, district1)
      assign(:zones, [zone1])
      assign(:facility_sizes, [size_small])
      render
    end

    it "defaults to the first district for facility group" do
      expect(rendered).to include("District 1")
      expect(rendered).not_to include("All districts")
    end

    it "defaults to 'All blocks' for zone filter but shows only district's zones" do
      allow(CountryConfig).to receive(:current).and_return("Bangladesh")
      render

      if CountryConfig.current == "Bangladesh"
        expect(rendered).to include("All upazilas")
      end
    end

    it "defaults to 'All facility sizes' for size filter but lists only the selected district's sizes" do
      expect(rendered).to include("All facility sizes")
      expect(rendered).to include("Small")
    end
  end
end
