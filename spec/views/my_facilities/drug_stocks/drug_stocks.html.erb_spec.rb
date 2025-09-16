require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/drug_stocks.html.erb", type: :view do
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
  let(:current_admin) { instance_double("Admin") }

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

    def my_facilities_csv_maker_path(options = {})
      "#{options[:type]}_csv_path"
    end

    def my_facilities_drug_stocks_path(*args)
      "/my_facilities/drug_stocks"
    end

    def preserve_query_params(params, _keys)
      params
    end

    def last_n_months(n:, inclusive:)
      [Date.new(2025, 8, 31)]
    end

    def action_name
      "drug_stocks"
    end

    def localized_facility_size(size)
      size.to_s.titleize
    end

    def protocol_drug_labels
      {
        hypertension: {full: "Hypertension Drugs"},
        diabetes: {full: "Diabetes Drugs"}
      }
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
    allow(view).to receive(:all_district_overview_enabled?).and_return(false)
  end

  context "when all_district_overview_enabled? is true" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(true)
      assign(:district_reports, {})
      render
    end

    it "renders the all_district_drug_stock_table partial" do
      expect(view).to have_rendered(partial: "_all_district_drug_stock_table")
    end
  end

  context "when facilities are present and all_district_overview_enabled? is false" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(false)
      assign(:facilities, [facility])
      render
    end

    it "renders the drug_stocks_table partial" do
      expect(view).to have_rendered(partial: "_drug_stocks_table")
    end

    it "renders the 'Download Report' link" do
      expect(rendered).to have_link("Download Report")
    end
  end

  context "when no data is present" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(false)
      assign(:facilities, [])
      render
    end

    it "shows no data message" do
      expect(rendered).to match(/There is no data for this selection/)
    end

    it "does not render the 'Download Report' link" do
      expect(rendered).not_to have_link("Download Report")
    end
  end

  it "renders the page title with end of month" do
    render
    expect(rendered).to include("Stock on hand: end of Aug-2025")
  end
end
