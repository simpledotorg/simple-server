require "rails_helper"

RSpec.describe "my_facilities/_all_district_drug_consumption.html.erb", type: :view do
  let(:district1_goa) { double(id: 1, name: "District_1", state: "Goa", slug: "district_1") }
  let(:district2_goa) { double(id: 2, name: "District_2", state: "Goa", slug: "district_2") }
  let(:district1_up) { double(id: 3, name: "District_1", state: "UP", slug: "district_1_up") }
  let(:district2_up) { double(id: 4, name: "District_2", state: "UP", slug: "district_2_up") }

  let(:drug1) { double(id: 101, name: "Drug X", dosage: "10mg", rxnorm_code: "X101") }
  let(:drug2) { double(id: 102, name: "Drug Y", dosage: "20mg", rxnorm_code: "Y102") }
  let(:drugs_by_category) { { "hypertension" => [drug1, drug2] } }

  let(:report_goa_d1) { { district_patient_count: 50, facilities_total_patient_count: 50, drug_consumption: { "X101" => 30, "Y102" => 35 } } }
  let(:report_goa_d2) { { district_patient_count: 60, facilities_total_patient_count: 60, drug_consumption: { "X101" => 20, "Y102" => 35 } } }
  let(:report_up_d1)  { { district_patient_count: 50, facilities_total_patient_count: 50, drug_consumption: { "X101" => 30, "Y102" => 20 } } }
  let(:report_up_d2)  { { district_patient_count: 70, facilities_total_patient_count: 70, drug_consumption: { "X101" => 25, "Y102" => 15 } } }

  let(:district_reports) do
    {
      district1_goa => { report: report_goa_d1, drugs_by_category: drugs_by_category },
      district2_goa => { report: report_goa_d2, drugs_by_category: drugs_by_category },
      district1_up => { report: report_up_d1, drugs_by_category: drugs_by_category },
      district2_up => { report: report_up_d2, drugs_by_category: drugs_by_category }
    }
  end

  before do
    assign(:district_reports, district_reports)
    assign(:protocol_drug_labels, "hypertension": { full: "Hypertension Drugs", short: "HTN" })
    assign(:for_end_of_month_display, Date.today)
    render
  end

  it "renders All row with total patients and drug consumption" do
    expect(rendered).to include("All")
    expect(rendered).to include("230")
    expect(rendered).to include("105")
    expect(rendered).to include("105")
  end

  it "renders Goa subtotal row correctly" do
    expect(rendered).to include("Goa")
    expect(rendered).to include("110")
    expect(rendered).to include("50")
    expect(rendered).to include("70")
  end

  it "renders UP subtotal row correctly" do
    expect(rendered).to include("UP")
    expect(rendered).to include("120")
    expect(rendered).to include("55")
    expect(rendered).to include("35")
  end

  it "renders all district rows correctly" do
    # Goa districts
    expect(rendered).to include("District_1")
    expect(rendered).to include("30")
    expect(rendered).to include("35")

    expect(rendered).to include("District_2")
    expect(rendered).to include("20")
    expect(rendered).to include("35")

    # UP districts
    expect(rendered).to include("District_1")
    expect(rendered).to include("30")
    expect(rendered).to include("20")

    expect(rendered).to include("District_2")
    expect(rendered).to include("25")
    expect(rendered).to include("15")
  end
end