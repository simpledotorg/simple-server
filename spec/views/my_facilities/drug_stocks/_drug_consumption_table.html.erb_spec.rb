require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_drug_consumption_table.html.erb", type: :view do
  let(:facility1) { double("Facility", id: 1, name: "Facility 1") }
  let(:facility2) { double("Facility", id: 2, name: "Facility 2") }
  let(:block1) { double("Region", id: 1, name: "Block 1") }
  let(:district_region) { double("Region", id: 99, name: "District 1") }

  let(:drug) { double("Drug", id: 101, name: "Drug X", dosage: "10mg") }
  let(:drugs_by_category) { {"hypertension" => [drug]} }

  let(:report) do
    {
      total_patient_count: 120, # District total
      district_patient_count: 120, # District total
      facilities_total_patient_count: 120, # Sum of all facilities
      patient_count_by_block_id: {1 => 120}, # Block total (sum of facilities)
      patient_count_by_facility_id: {1 => 50, 2 => 70}, # Facility totals
      total_drug_consumption: {},
      district_drug_consumption: {},
      drug_consumption_by_block_id: {},
      facilities_total_drug_consumption: {},
      drug_consumption_by_facility_id: {}
    }
  end

  before do
    assign(:facilities, [facility1, facility2])
    assign(:blocks, [block1])
    assign(:district_region, district_region)
    assign(:drugs_by_category, drugs_by_category)
    assign(:report, report)

    allow(view).to receive(:protocol_drug_labels).and_return(
      hypertension: {full: "Hypertension Drugs", short: "HTN"}
    )
    allow(view).to receive(:reports_region_path) { |region, opts| "/reports/#{region.id}?scope=#{opts[:report_scope]}" }
    allow(view).to receive(:drug_stock_region_label).and_return("District 1")

    render
  end

  it "renders the total patients in 'All' row" do
    expect(rendered).to have_selector("tr.row-total td.type-number", text: "120")
  end

  it "renders district patient count in 'Patients under care' column" do
    district_row = Nokogiri::HTML(rendered).css("tr").find { |tr| tr.text.include?("District 1") }
    patient_count_cell = district_row.css("td.type-number[data-sort-value]").first
    expect(patient_count_cell["data-sort-value"]).to eq("120")
  end

  it "renders block patient count in 'Patients under care' column" do
    block_row = Nokogiri::HTML(rendered).css("tr").find { |tr| tr.text.include?("Block 1") }
    patient_count_cell = block_row.css("td.type-number[data-sort-value]").first
    expect(patient_count_cell.text.strip).to eq("120")
  end

  it "renders facility patient counts in 'Patients under care' column" do
    facility1_row = Nokogiri::HTML(rendered).css("tr").find { |tr| tr.text.include?("Facility 1") }
    facility1_cell = facility1_row.css("td.type-number[data-sort-value]").first
    expect(facility1_cell.text.strip).to eq("50")

    facility2_row = Nokogiri::HTML(rendered).css("tr").find { |tr| tr.text.include?("Facility 2") }
    facility2_cell = facility2_row.css("td.type-number[data-sort-value]").first
    expect(facility2_cell.text.strip).to eq("70")
  end

  it "renders facilities subtotal patient count" do
    subtotal_row = Nokogiri::HTML(rendered).css("tr.row-total").find { |tr| tr.text.include?("Facilities subtotal") }
    patient_count_cell = subtotal_row.css("td.type-number[data-sort-column-key='patients_under_care']").first
    expect(patient_count_cell.text.strip).to eq("120")
  end
end
