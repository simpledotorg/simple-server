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
      total_patient_count: 120,
      district_patient_count: 120,
      facilities_total_patient_count: 120,
      patient_count_by_block_id: {1 => 120},
      patient_count_by_facility_id: {1 => 50, 2 => 70},
      total_drug_consumption: {},
      district_drug_consumption: {},
      drug_consumption_by_block_id: {},
      facilities_total_drug_consumption: {},
      drug_consumption_by_facility_id: {}
    }
  end

  let(:current_admin) { create(:admin, :manager) }

  helper do
    def protocol_drug_labels
      {hypertension: {full: "Hypertension Drugs", short: "HTN"}}
    end

    def reports_region_path(region, opts = {})
      "/reports/#{region.id}?scope=#{opts[:report_scope]}"
    end

    def drug_stock_region_label(*)
      "District 1"
    end

    def accessible_organization_facilities
      true
    end

    attr_reader :current_admin
  end

  before do
    @current_admin = current_admin
    allow(view).to receive(:access_all_districts_overview?).and_return(true)
    assign(:facilities, [facility1, facility2])
    assign(:blocks, [block1])
    assign(:district_region, district_region)
    assign(:drugs_by_category, drugs_by_category)
    assign(:report, report)

    allow(Flipper).to receive(:enabled?).with(:all_district_overview, current_admin).and_return(true)
    allow(view).to receive(:access_all_districts_overview?).and_return(true)
    render
  end

  let(:doc) { Nokogiri::HTML(rendered) }

  def patient_count_for_row(text)
    row = doc.css("tr").find { |tr| tr.text.include?(text) }
    row.css("td.type-number").first.text.strip
  end

  it "renders the total patients in 'All' row" do
    expect(patient_count_for_row("All")).to eq("120")
  end

  it "renders district patient count in 'Patients under care' column" do
    expect(patient_count_for_row("District 1")).to eq("120")
  end

  it "renders block patient count in 'Patients under care' column" do
    expect(patient_count_for_row("Block 1")).to eq("120")
  end

  it "renders facility patient counts in 'Patients under care' column" do
    expect(patient_count_for_row("Facility 1")).to eq("50")
    expect(patient_count_for_row("Facility 2")).to eq("70")
  end

  it "renders facilities subtotal patient count" do
    expect(patient_count_for_row("Facilities subtotal")).to eq("120")
  end
end
