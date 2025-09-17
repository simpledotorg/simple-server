require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_drug_stocks_table.html.erb", type: :view do
  let(:facility1) { double("Facility", id: 1, name: "Facility 1", region: double(id: 1)) }
  let(:facility2) { double("Facility", id: 2, name: "Facility 2", region: double(id: 1)) }
  let(:block1) { double("Region", id: 1, name: "Block 1") }
  let(:district_region) { double("Region", id: 99, name: "District 1") }

  let(:drugs_by_category) do
    {
      "hypertension" => [
        double(id: 101, name: "Drug X", dosage: "10mg", rxnorm_code: "X101")
      ]
    }
  end

  let(:report) do
    {
      total_patient_count: 120,
      facilities_total_patient_count: 120,
      patient_count_by_block_id: {1 => 120},
      patient_count_by_facility_id: {1 => 50, 2 => 70},
      total_drugs_in_stock: {"X101" => 120},
      district_drugs_in_stock: {"X101" => 120},
      facilities_total_drugs_in_stock: {"X101" => 120},
      drugs_in_stock_by_facility_id: {[1, "X101"] => 50, [2, "X101"] => 70},
      drugs_in_stock_by_block_id: {[1, "X101"] => 120}
    }
  end

  before do
    assign(:facilities, [facility1, facility2])
    assign(:blocks, [block1])
    assign(:district_region, district_region)
    assign(:drugs_by_category, drugs_by_category)
    assign(:report, report)
    assign(:for_end_of_month_display, true)

    allow(view).to receive(:protocol_drug_labels).and_return(
      hypertension: {full: "Hypertension Drugs", short: "HTN"}
    )
    allow(view).to receive(:reports_region_path) { |region, opts| "/reports/#{region.id}?scope=#{opts[:report_scope]}" }
    allow(view).to receive(:drug_stock_region_label).and_return("District 1")
    allow(view).to receive(:patient_days_css_class).and_return("bg-green")
    allow(view).to receive(:my_facilities_drug_stock_form_path) { |id, opts| "/drug_stock_form/#{id}" }
    allow(Flipper).to receive(:enabled?).with("all_district_overview").and_return(true)
    allow(view).to receive(:accessible_organization_facilities).and_return(true)
    render
  end

  it "renders the 'Patients under care' header" do
    expect(rendered).to have_selector("th.row-label[data-sort-column-key='patients_under_care']", text: /Patients\s*under\s*care/i)
  end

  it "renders the total patients in 'All' row" do
    expect(rendered).to have_selector("td.type-number[data-sort-column-key='patients_under_care']", text: "120")
  end

  it "renders block patient count in 'Patients under care' column" do
    expect(rendered).to have_selector("tr td.type-number[data-sort-column-key='patients_under_care']", text: "120")
  end

  it "renders facility patient counts in 'Patients under care' column" do
    expect(rendered).to have_selector("tr td.type-number[data-sort-column-key='patients_under_care']", text: "50")
    expect(rendered).to have_selector("tr td.type-number[data-sort-column-key='patients_under_care']", text: "70")
  end

  it "renders facilities subtotal patient count" do
    expect(rendered).to have_selector("tr td.type-number[data-sort-column-key='patients_under_care']", text: "120")
  end
end
