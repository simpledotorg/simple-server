require "rails_helper"

RSpec.describe "my_facilities/all_district_drug_stock_table.html.erb", type: :view do
  let(:district1) { double(id: 1, name: "District 1", slug: "district-1", state: "Goa") }
  let(:district2) { double(id: 2, name: "District 2", slug: "district-2", state: "Goa") }
  let(:district3) { double(id: 3, name: "District 1", slug: "district-1-up", state: "UP") }
  let(:district4) { double(id: 4, name: "District 2", slug: "district-2-up", state: "UP") }

  let(:drug1) { double(id: 101, name: "Drug X", dosage: "10mg", rxnorm_code: "X101") }
  let(:drug2) { double(id: 102, name: "Drug Y", dosage: "20mg", rxnorm_code: "Y102") }

  let(:first_drugs_by_category) { { "hypertension" => [drug1, drug2] } }

  let(:report_data) do
    {
      district_patient_count: 50,
      facilities_total_patient_count: 50,
      total_drugs_in_stock: { "X101" => 30, "Y102" => 20 },
      drugs_in_stock_by_facility_id: { [1, "X101"] => 30, [1, "Y102"] => 20 },
      total_patient_days: { "hypertension" => { patient_days: 40 } }
    }
  end

  let(:district_reports) do
    {
      district1 => { report: report_data.merge(district_patient_count: 50, total_drugs_in_stock: { "X101" => 30, "Y102" => 35 }, total_patient_days: { "hypertension" => { patient_days: 40 } }) },
      district2 => { report: report_data.merge(district_patient_count: 60, total_drugs_in_stock: { "X101" => 25, "Y102" => 35 }, total_patient_days: { "hypertension" => { patient_days: 40 } }) },
      district3 => { report: report_data.merge(district_patient_count: 50, total_drugs_in_stock: { "X101" => 30, "Y102" => 20 }, total_patient_days: { "hypertension" => { patient_days: 45 } }) },
      district4 => { report: report_data.merge(district_patient_count: 70, total_drugs_in_stock: { "X101" => 25, "Y102" => 15 }, total_patient_days: { "hypertension" => { patient_days: 40 } }) }
    }
  end

  before do
    assign(:district_reports, district_reports)
    assign(:for_end_of_month_display, Date.today.end_of_month)
    allow(view).to receive(:protocol_drug_labels).and_return(
      "hypertension": { full: "Hypertension Drugs", short: "HTN" }
    )
    allow(view).to receive(:my_facilities_drug_stocks_path) { |opts| "/drug_stocks?facility_group=#{opts[:facility_group]}" }
    allow(view).to receive(:patient_days_css_class).and_return("bg-green")
    render
  end

  it "renders All states total row correctly" do
    expect(rendered).to include("All")
    expect(rendered).to include("230")
    expect(rendered).to include("105")
    expect(rendered).to include("105")
    expect(rendered).to include("165")
  end

  it "renders state subtotal rows correctly" do
    expect(rendered).to include("Goa")
    expect(rendered).to include("110")
    expect(rendered).to include("50")
    expect(rendered).to include("70")
    expect(rendered).to include("80")

    expect(rendered).to include("UP")
    expect(rendered).to include("120")
    expect(rendered).to include("55")
    expect(rendered).to include("35")
    expect(rendered).to include("85")
  end

  it "renders district rows correctly" do
    expect(rendered).to include("District 1")
    expect(rendered).to include("50")
    expect(rendered).to include("30")
    expect(rendered).to include("35")
    expect(rendered).to include("40")

    expect(rendered).to include("District 2")
    expect(rendered).to include("60")
    expect(rendered).to include("25")
    expect(rendered).to include("35")
    expect(rendered).to include("40")
  end

  it "renders links to individual district drug stock pages" do
    district_reports.each_key do |district|
      expect(rendered).to include("/drug_stocks?facility_group=#{district.slug}")
    end
  end
end