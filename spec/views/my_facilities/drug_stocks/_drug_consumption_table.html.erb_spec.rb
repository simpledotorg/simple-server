require "rails_helper"

RSpec.describe "my_facilities/_drug_consumption_table.html.erb", type: :view do
  let(:facility1) { double(id: 1, name: "Facility 1") }
  let(:facility2) { double(id: 2, name: "Facility 2") }

  let(:block1) { double(id: 1, name: "Block 1") }
  let(:block2) { double(id: 2, name: "Block 2") }

  let(:drug1) { double(id: 101, name: "Drug X", dosage: "10mg") }
  let(:drug2) { double(id: 102, name: "Drug Y", dosage: "20mg") }

  let(:drugs_by_category) { { hypertension: [drug1, drug2] } }

  let(:report) do
    {
      total_patient_count: 110,     
      district_patient_count: 110,  
      facilities_total_patient_count: 110, 
      all_drug_consumption: {
        hypertension: {
          drug1 => { consumed: 55 },
          drug2 => { consumed: 35 },
          base_doses: { total: 90 }
        }
      },
      total_drug_consumption: {
        hypertension: {
          drug1 => { consumed: 55 },
          drug2 => { consumed: 35 },
          base_doses: { total: 90 }
        }
      },
      facilities_total_drug_consumption: {
        hypertension: {
          drug1 => { consumed: 55 },
          drug2 => { consumed: 35 },
          base_doses: { total: 90 }
        }
      },
      drug_consumption_by_facility_id: {
        1 => { hypertension: { drug1 => { consumed: 30 }, drug2 => { consumed: 20 }, base_doses: { total: 50 } } },
        2 => { hypertension: { drug1 => { consumed: 25 }, drug2 => { consumed: 15 }, base_doses: { total: 40 } } }
      },
      patient_count_by_facility_id: { 1 => 50, 2 => 60 },
      patient_count_by_block_id: { 1 => 50, 2 => 60 },
      drug_consumption_by_block_id: {
        1 => { hypertension: { drug1 => { consumed: 30 }, drug2 => { consumed: 20 }, base_doses: { total: 50 } } },
        2 => { hypertension: { drug1 => { consumed: 25 }, drug2 => { consumed: 15 }, base_doses: { total: 40 } } }
      },
      district_drug_consumption: {
        hypertension: { drug1 => { consumed: 55 }, drug2 => { consumed: 35 }, base_doses: { total: 90 } }
      }
    }
  end

  before do
    assign(:facilities, [facility1, facility2])
    assign(:blocks, [block1, block2])
    assign(:drugs_by_category, drugs_by_category)
    assign(:report, report)
    assign(:district_region, double(id: 1, name: "District 1"))

    allow(view).to receive(:protocol_drug_labels).and_return(
      hypertension: { full: "Hypertension Drugs", short: "HTN" }
    )
    allow(view).to receive(:reports_region_path) { |region, opts| "/reports/#{region.id}?scope=#{opts[:report_scope]}" }
    allow(view).to receive(:drug_stock_region_label).and_return("District 1")

    render
  end

  it "renders table headers correctly" do
    expect(rendered).to have_selector("th.row-label", text: "Facilities")
    expect(rendered).to have_selector("th.row-label", text: "Patients under care")
    expect(rendered).to have_selector("th.row-label", text: "Drug X")
    expect(rendered).to have_selector("th.row-label", text: "Drug Y")
  end

  it "renders 'All' row with district totals" do
    expect(rendered).to have_selector("tr.row-total td.type-title", text: "All")
    expect(rendered).to include("110") 
    expect(rendered).to include("55")  
    expect(rendered).to include("35")  
  end

  it "renders blocks with their facility totals" do
    expect(rendered).to include("Block 1")
    expect(rendered).to include("50") 
    expect(rendered).to include("30")
    expect(rendered).to include("20")

    expect(rendered).to include("Block 2")
    expect(rendered).to include("60") nts in block 2
    expect(rendered).to include("25")
    expect(rendered).to include("15")
  end

  it "renders facilities subtotal row correctly" do
    expect(rendered).to have_selector("tr.row-total td.type-title", text: "Facilities subtotal")
    expect(rendered).to include("110")
    expect(rendered).to include("55") 
    expect(rendered).to include("35") 
  end

  it "renders individual facility rows" do
    expect(rendered).to include("Facility 1")
    expect(rendered).to include("50")
    expect(rendered).to include("30")
    expect(rendered).to include("20") 

    expect(rendered).to include("Facility 2")
    expect(rendered).to include("60")
    expect(rendered).to include("25") 
    expect(rendered).to include("15") 
  end
end
