# spec/views/my_facilities/drug_stocks.html.erb_spec.rb
require "rails_helper"

RSpec.describe "my_facilities/drug_stocks.html.erb", type: :view do
  let(:facility) { double(id: 1, name: "Facility 1") }

  before do
    assign(:for_end_of_month_display, "Aug-2025")
    assign(:for_end_of_month, Date.new(2025, 8, 31))
    assign(:show_current_month, false)
    assign(:facilities, [facility])
    assign(:district_reports, {})
    allow(view).to receive(:last_n_months).and_return([Date.new(2025, 8, 31)])
  end

  context "when all_district_overview_enabled? is true" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(true)
      render
    end

    it "renders the all_district_drug_stock_table partial" do
      expect(view).to render_template(partial: "_all_district_drug_stock_table")
    end
  end

  context "when facilities are present and all_district_overview_enabled? is false" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(false)
      render
    end

    it "renders the drug_stocks_table partial" do
      expect(view).to render_template(partial: "_drug_stocks_table")
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
  end

  it "renders the page title with end of month" do
    render
    expect(rendered).to match(/Stock on hand: end of Aug-2025/)
  end

  it "renders the download CSV button if facilities exist" do
    render
    expect(rendered).to have_link("Download Report")
  end
end
