require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/drug_consumption.html.erb", type: :view do
  let(:region) { instance_double("Region", id: 123) }
  let(:facility) do
    instance_double(
      "Facility",
      id: 1,
      name: "Facility 1",
      localized_facility_size: "Small",
      region: region
    )
  end
  let(:district1) { instance_double("FacilityGroup", id: 1, name: "District 1", slug: "district-1", state: "State 1") }
  let(:district2) { instance_double("FacilityGroup", id: 2, name: "District 2", slug: "district-2", state: "State 2") }
  let(:organization_region) { create(:region, name: "Organization", region_type: "organization", path: "organization.path") }
  let(:current_admin) { double("Admin") }

  helper do
    def accessible_region?(*args)
      true
    end

    def active_action?(*args)
      false
    end

    def t(key, **args)
      key.to_s.titleize
    end

    attr_reader :current_admin

    def my_facilities_drug_consumption_path(options = {})
      "/my_facilities/drug_consumption.csv"
    end

    def preserve_query_params(params, _keys)
      params
    end

    def last_n_months(n:, inclusive:)
      [Date.new(2025, 8, 31)]
    end

    def action_name
      "drug_consumption"
    end

    def localized_facility_size(size)
      size.to_s.titleize
    end
  end

  before do
    assign(:current_admin, current_admin)
    assign(:for_end_of_month_display, "Aug-2025")
    assign(:for_end_of_month, Date.new(2025, 8, 31))
    assign(:show_current_month, false)

    assign(:selected_zones, [])
    assign(:selected_facility_sizes, [])
    assign(:facility_groups, [district1, district2])
    assign(:zones, ["zone1", "zone2"])
    assign(:facility_sizes, ["small", "medium"])

    allow(current_admin).to receive(:feature_enabled?).and_return(true)
    allow(view).to receive(:request).and_return(double("Request", query_parameters: {}, path: "/test"))
    allow(view).to receive(:params).and_return({})
    allow(view).to receive(:access_all_districts_overview?).and_return(false)
  end

  it "displays the heading with the selected month" do
    render
    expect(rendered).to have_selector("h3", text: "Drug consumption during Aug-2025")
  end

  it "renders the consumption formula badges" do
    render
    expect(rendered).to have_selector("span.badge", text: "CLOSING BALANCE OF PREVIOUS MONTH")
    expect(rendered).to have_selector("span.badge", text: "STOCK RECEIVED THIS MONTH")
    expect(rendered).to have_selector("span.badge", text: "CLOSING BALANCE OF THIS MONTH")
    expect(rendered).to have_selector("span.badge", text: "STOCK ISSUED TO OTHER FACILITIES THIS MONTH")
  end

  it "renders the month dropdown with the current month selected" do
    render
    expect(rendered).to have_selector("a#dropdownMenuLink", text: "Aug-2025")
  end

  context "when facilities are present" do
    before do
      assign(:facilities, [facility])
      render
    end

    it "renders a Download Report button" do
      expect(rendered).to have_link("Download Report", href: "/my_facilities/drug_consumption.csv")
    end
  end

  context "when access_all_districts_overview? is true" do
    before do
      allow(view).to receive(:access_all_districts_overview?).and_return(true)
      assign(:district_reports, {})
      render
    end

    it "renders the all district drug consumption table partial" do
      expect(view).to have_rendered(partial: "_all_district_drug_consumption_table")
    end
  end

  context "when facilities are present and access_all_districts_overview? is false" do
    before do
      allow(view).to receive(:access_all_districts_overview?).and_return(false)
      assign(:facilities, [facility])
      render
    end

    it "renders the drug consumption table partial" do
      expect(view).to have_rendered(partial: "_drug_consumption_table")
    end
  end

  context "when no facilities are present" do
    before do
      allow(view).to receive(:access_all_districts_overview?).and_return(false)
      assign(:facilities, [])
      render
    end

    it "shows no data message" do
      expect(rendered).to match(/There is no data for this selection/)
    end

    it "does not render the Download Report button" do
      expect(rendered).not_to have_link("Download Report")
    end
  end
end
