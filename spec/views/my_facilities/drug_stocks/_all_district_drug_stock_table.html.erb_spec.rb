require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_all_district_drug_consumption_table.html.erb", type: :view do
  let(:district1) { double("District", id: 1, name: "Babraich", slug: "babraich", state: "Goa", division: "North Goa") }
  let(:district2) { double("District", id: 2, name: "Mansa", slug: "mansa", state: "Goa", division: "South Goa") }

  let(:drug1) { double("Drug", id: 101, name: "Amlodipine 5 mg", dosage: "5mg", rxnorm_code: "X101") }
  let(:drug2) { double("Drug", id: 102, name: "Losartan 50 mg", dosage: "50mg", rxnorm_code: "Y102") }

  let(:district_reports) do
    {
      district1 => {
        report: {
          district_patient_count: 139,
          facilities_total_patient_count: 100,
          total_drug_consumption: {
            hypertension: {
              drug1 => {consumed: 10},
              drug2 => {consumed: 5}
            }
          },
          total_patient_days: {hypertension: 0}
        },
        drugs_by_category: {hypertension: [drug1, drug2]}
      },
      district2 => {
        report: {
          district_patient_count: 524,
          facilities_total_patient_count: 400,
          total_drug_consumption: {
            hypertension: {
              drug1 => {consumed: 20},
              drug2 => {consumed: 15}
            }
          },
          total_patient_days: {hypertension: 0}
        },
        drugs_by_category: {hypertension: [drug1, drug2]}
      }
    }
  end

  before do
    assign(:district_reports, district_reports)
    assign(:for_end_of_month_display, "Sep-2025")

    allow(view).to receive(:protocol_drug_labels).and_return(
      hypertension: {full: "Hypertension Drugs", short: "HTN"}
    )

    allow(view).to receive(:my_facilities_drug_consumption_path) do |opts|
      "/drug_consumption?facility_group=#{opts[:facility_group]}&for_end_of_month=#{opts[:for_end_of_month]}"
    end

    render partial: "my_facilities/drug_stocks/all_district_drug_consumption_table",
      locals: {district_reports: district_reports}
  end

  it "renders the 'Patients under care' column for all rows" do
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "139")
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "524")
    expect(rendered).to have_selector("tr.row-total td.type-number", text: "663")
  end

  it "renders district names with links" do
    district_reports.keys.each do |district|
      expect(rendered).to have_link(district.name, href: "/drug_consumption?facility_group=#{district.slug}&for_end_of_month=Sep-2025")
    end
  end

  it "renders Goa subtotal row with correct name and value" do
    # allow for "Subtotal" text in different forms/case
    expect(rendered).to match(/Goa.*Subtotal/i)
    expect(rendered).to match(/663/)
    expect(rendered).to match(/30/)
    expect(rendered).to match(/20/)
  end

  it "renders All row with correct totals" do
    expect(rendered).to have_selector("tr.row-total td.type-title", text: "All")
    expect(rendered).to have_selector("tr.row-total td.type-number", text: "663")
    expect(rendered).to have_selector("tr.row-total td.type-number", text: "30")
    expect(rendered).to have_selector("tr.row-total td.type-number", text: "20")
  end

  it "renders drug headers dynamically" do
    expect(rendered).to match(/Amlodipine 5 mg/)
    expect(rendered).to match(/Losartan 50 mg/)
  end

  it "renders correct drug consumption values for districts" do
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "10")
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "5")
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "20")
    expect(rendered).to have_selector("tr.district-row td.type-number", text: "15")
  end
end
