require "rails_helper"

RSpec.describe "my_facilities/_drug_stock_table.html.erb", type: :view do
  let(:facility1) { double(id: 1, name: "Facility 1", region: double(id: 1)) }
  let(:facility2) { double(id: 2, name: "Facility 2", region: double(id: 2)) }

  let(:block1) { double(id: 1, name: "Block 1") }
  let(:block2) { double(id: 2, name: "Block 2") }

  let(:drug1) { double(id: 101, name: "Drug X", dosage: "10mg", rxnorm_code: "X101") }
  let(:drug2) { double(id: 102, name: "Drug Y", dosage: "20mg", rxnorm_code: "Y102") }

  let(:drugs_by_category) { { "hypertension" => [drug1, drug2] } }

  let(:report) do
    {
      total_patient_count: 110,
      district_patient_count: 110,
      facilities_total_patient_count: 110,
      total_drugs_in_stock: { "X101" => 55, "Y102" => 35 },
      district_drugs_in_stock: { "X101" => 55, "Y102" => 35 },
      facilities_total_drugs_in_stock: { "X101" => 55, "Y102" => 35 },
      patient_count_by_facility_id: { 1 => 50, 2 => 60 },
      patient_count_by_block_id: { 1 => 50, 2 => 60 },
      patient_days_by_facility_id: { 1 => { "hypertension" => { patient_days: 45 } }, 2 => { "hypertension" => { patient_days: 40 } } },
      patient_days_by_block_id: { 1 => { "hypertension" => { patient_days: 45 } }, 2 => { "hypertension" => { patient_days: 40 } } },
      total_patient_days: { "hypertension" => { patient_days: 85 } },
      facilities_total_patient_days: { "hypertension" => { patient_days: 85 } },
      drugs_in_stock_by_facility_id: { [1, "X101"] => 30, [1, "Y102"] => 20, [2, "X101"] => 25, [2, "Y102"] => 15 }
    }
  end

  before do
    assign(:facilities, [facility1, facility2])
    assign(:blocks, [block1, block2])
    assign(:drugs_by_category, drugs_by_category)
    assign(:report, report)
    assign(:district_region, double(id: 1, name: "District 1"))

    allow(view).to receive(:protocol_drug_labels).and_return(
      "hypertension": { full: "Hypertension Drugs", short: "HTN" }
    )
    allow(view).to receive(:reports_region_path) { |region, opts| "/reports/#{region.id}?scope=#{opts[:report_scope]}" }
    allow(view).to receive(:drug_stock_region_label).and_return("District 1")
    allow(view).to receive(:patient_days_css_class).and_return("bg-green")
    allow(view).to receive(:my_facilities_drug_stock_form_path) { |id, opts| "/drug_stock_form/#{id}" }

    render
  end

  it "renders table headers correctly" do
    expect(rendered).to have_selector("th.row-label", text: "Facilities")
    expect(rendered).to have_selector("th.row-label", text: "Patients under care")
    expect(rendered).to have_selector("th.row-label", text: "Drug X")
    expect(rendered).to have_selector("th.row-label", text: "Drug Y")
  end

  it "renders All row with total patients and drug stock" do
    expect(rendered).to include("All")
    expect(rendered).to include("110") 
    expect(rendered).to include("55") 
    expect(rendered).to include("35") 
    expect(rendered).to include("85") 
  end
    
  it "renders block rows with their patient counts, drug stock, and patient days" do
    expect(rendered).to include("Block 1")
    expect(rendered).to include("50") 
    expect(rendered).to include("30")
    expect(rendered).to include("20")
    expect(rendered).to include("45") 

    expect(rendered).to include("Block 2")
    expect(rendered).to include("60") 
    expect(rendered).to include("25") 
    expect(rendered).to include("15") 
    expect(rendered).to include("40") 
  end

  it "renders facilities rows correctly" do
    expect(rendered).to include("Facility 1")
    expect(rendered).to include("30")
    expect(rendered).to include("20")
    expect(rendered).to include("45")

    expect(rendered).to include("Facility 2")
    expect(rendered).to include("25")
    expect(rendered).to include("15")
    expect(rendered).to include("40")
  end

  it "renders Facilities subtotal row correctly" do
    expect(rendered).to include("Facilities subtotal")
    expect(rendered).to include("55")
    expect(rendered).to include("35")
    expect(rendered).to include("85")
  end
end