drug_consumption.html.erb_spec.rbrequire "rails_helper"

RSpec.describe "my_facilities/drug_consumption.html.erb", type: :view do
  let(:facility) { double(id: 1, name: "Facility 1") }

  before do
    assign(:for_end_of_month_display, "Aug-2025")
    assign(:facilities, [facility])
  end

  context "when all_district_overview_enabled? is true" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(true)
      assign(:district_reports, {})
      render
    end

    it "renders the all_district_drug_consumption_table partial" do
      expect(view).to render_template(partial: "_all_district_drug_consumption_table")
    end
  end

  context "when facilities are present and all_district_overview_enabled? is false" do
    before do
      allow(view).to receive(:all_district_overview_enabled?).and_return(false)
      render
    end

    it "renders the drug_consumption_table partial" do
      expect(view).to render_template(partial: "_drug_consumption_table")
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

  it "renders the page title" do
    render
    expect(rendered).to match(/Drug consumption during Aug-2025/)
  end

  it "renders the download CSV button if facilities exist" do
    render
    expect(rendered).to have_link("Download Report")
  end
end
