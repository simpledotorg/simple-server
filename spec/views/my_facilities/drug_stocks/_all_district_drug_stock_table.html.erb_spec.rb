require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_all_district_drug_stock_table.html.erb", type: :view do
  let(:district1) { double("District", id: 1, name: "Babraich", slug: "babraich", state: "Goa") }
  let(:district2) { double("District", id: 2, name: "Mansa", slug: "mansa", state: "Goa") }

  let(:drug1) { double("Drug", id: 101, name: "Amlodipine 5 mg", dosage: "5mg", rxnorm_code: "X101") }
  let(:drug2) { double("Drug", id: 102, name: "Losartan 50 mg", dosage: "50mg", rxnorm_code: "Y102") }

  let(:district_reports) do
    {
      district1 => {
        report: {
          district_patient_count: 139,
          facilities_total_patient_count: 100,
          total_drugs_in_stock: {"X101" => 0, "Y102" => 0},
          drugs_in_stock_by_facility_id: {[1, "X101"] => 0, [1, "Y102"] => 0},
          total_patient_days: {"hypertension" => {patient_days: 20}}
        },
        drugs_by_category: {"hypertension" => [drug1, drug2]}
      },
      district2 => {
        report: {
          district_patient_count: 524,
          facilities_total_patient_count: 400,
          total_drugs_in_stock: {"X101" => 0, "Y102" => 0},
          drugs_in_stock_by_facility_id: {[2, "X101"] => 0, [2, "Y102"] => 0},
          total_patient_days: {"hypertension" => {patient_days: 50}}
        },
        drugs_by_category: {"hypertension" => [drug1, drug2]}
      }
    }
  end

  before do
    assign(:district_reports, district_reports)
    assign(:for_end_of_month_display, "Sep-2025")

    allow(view).to receive(:protocol_drug_labels).and_return(
      hypertension: {full: "Hypertension Drugs", short: "HTN"}
    )
    allow(view).to receive(:patient_days_css_class).and_return("bg-green")
    allow(view).to receive(:my_facilities_drug_stocks_path) do |opts|
      "/drug_stocks?for_end_of_month=#{opts[:for_end_of_month]}"
    end

    render partial: "my_facilities/drug_stocks/all_district_drug_stock_table",
      locals: {district_reports: district_reports}
  end

  it "renders the 'District' column header" do
    expect(rendered).to have_selector("th.row-label", text: /District/i)
  end

  it "renders 'Patients under care' column correctly for all rows" do
    expect(rendered).to have_selector("tr", text: /Babraich.*139/m)
    expect(rendered).to have_selector("tr", text: /Mansa.*524/m)
    expect(rendered).to have_selector("tr", text: /Goa subtotal.*663/m)
    expect(rendered).to have_selector("tr", text: /All.*663/m)
  end

  it "renders Babraich row with correct name and value" do
    expect(rendered).to match(/Babraich.*139/m)
  end

  it "renders Mansa row with correct name and value" do
    expect(rendered).to match(/Mansa.*524/m)
  end

  it "renders Goa subtotal row with correct name and value" do
    expect(rendered).to have_selector("tr td", text: "Goa subtotal")
    expect(rendered).to have_selector("tr td", text: "663")
  end

  it "renders All row with correct name and value" do
    expect(rendered).to match(/All.*663/m)
  end

  it "renders drug headers dynamically" do
    expect(rendered).to match(/Amlodipine 5 mg/)
    expect(rendered).to match(/Losartan 50 mg/)
  end
end
