require "rails_helper"

RSpec.describe "my_facilities/_my_facilities_filters.html.erb", type: :view do
  let(:district1) { double("FacilityGroup", id: 1, name: "District 1", slug: "district-1") }
  let(:district2) { double("FacilityGroup", id: 2, name: "District 2", slug: "district-2") }

  let(:zone1) { "zone1" }
  let(:zone2) { "zone2" }

  let(:size_small) { "small" }
  let(:size_medium) { "medium" }

  before do
    assign(:facility_groups, [district1, district2])
    assign(:zones, [zone1, zone2])
    assign(:facility_sizes, [size_small, size_medium])
    assign(:selected_facility_group, nil)
    assign(:selected_zones, [])
    assign(:selected_facility_sizes, [])
    assign(:for_end_of_month_display, Date.today.strftime("%Y-%m-%d"))

    allow(view).to receive(:current_admin).and_return(double(feature_enabled?: false))
  end

  context "when all_district_overview Flipper flag is enabled" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(true)
      render
    end

    it "defaults to 'All districts' for facility group" do
      expect(rendered).to include("All districts")
    end

    it "lists all districts in facility group dropdown" do
      expect(rendered).to include("District 1")
      expect(rendered).to include("District 2")
    end

    it "defaults to 'All blocks' for zone filter" do
      expect(rendered).to include("All blocks")
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
      allow(view).to receive(:all_district_overview_enabled?).and_return(false)
      assign(:selected_facility_group, district1)
      assign(:zones, [zone1]) # only zone related to default district
      assign(:facility_sizes, [size_small]) # only size related to default district
      render
    end

    it "defaults to the first district for facility group" do
      expect(rendered).to include("District 1")
      expect(rendered).not_to include("All districts")
    end

    it "defaults to 'All blocks' for zone filter but shows only district's zones" do
      expect(rendered).to include("All blocks")
      expect(rendered).to include("Zone1")
    end

    it "defaults to 'All facility sizes' for size filter but lists only the selected district's sizes" do
      expect(rendered).to include("All facility sizes")
      expect(rendered).to include("Small")
    end
  end
end
