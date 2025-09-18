require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_drug_consumption_table.html.erb", type: :view do
  let(:drug) { instance_double("Drug", id: 101, name: "Drug X", dosage: "10mg") }

  let(:block) { instance_double("Region", id: 11, name: "Block 1") }
  let(:district_region) { instance_double("Region", id: 99, name: "District 1") }

  let(:facility1) { instance_double("Facility", id: 1, name: "Facility 1") }
  let(:facility2) { instance_double("Facility", id: 2, name: "Facility 2") }

  let(:report) do
    {
      total_patient_count: 120,
      district_patient_count: 120,
      patient_count: 120,
      patient_count_by_block_id: {block.id => 120},
      patient_count_by_facility_id: {1 => 50, 2 => 70},

      total_drug_consumption: {
        hypertension: {
          drug => {consumed: 12},
          :base_doses => {total: 12, drugs: [{consumed: 12}]}
        }
      },

      district_drug_consumption: {
        hypertension: {
          drug => {consumed: 12},
          :base_doses => {total: 12, drugs: [{consumed: 12}]}
        }
      },

      drug_consumption_by_block_id: {
        block.id => {
          hypertension: {
            drug => {consumed: 12},
            :base_doses => {total: 12, drugs: [{consumed: 12}]}
          }
        }
      },

      facilities_total_drug_consumption: {
        hypertension: {
          drug => {consumed: 12},
          :base_doses => {total: 12, drugs: [{consumed: 12}]}
        }
      },

      drug_consumption_by_facility_id: {
        1 => {
          hypertension: {
            drug => {consumed: 5},
            :base_doses => {total: 5, drugs: [{consumed: 5}]}
          }
        },
        2 => {
          hypertension: {
            drug => {consumed: 7},
            :base_doses => {total: 7, drugs: [{consumed: 7}]}
          }
        }
      }
    }
  end

  before do
    assign(:report, report)
    assign(:drugs_by_category, {hypertension: [drug]})
    assign(:blocks, [block])
    assign(:district_region, district_region)
    assign(:facilities, [facility1, facility2])

    def view.protocol_drug_labels
      {hypertension: {full: "Hypertension Drugs", short: "HTN"}}
    end

    def view.can_view_all_districts_nav?
      true
    end

    def view.reports_region_path(region, opts = {})
      "/reports/#{region.id}?scope=#{opts[:report_scope]}"
    end

    def view.drug_stock_region_label(region)
      "District 1"
    end

    render
  end

  let(:doc) { Nokogiri::HTML(rendered) }

  def patient_count_for_row(row_text)
    row = doc.css("tr").find { |tr| tr.text.include?(row_text) }
    return nil unless row

    cell = row.at_css('td.type-number[data-sort-column-key="patients_under_care"]') || row.at_css("td.type-number")
    cell&.text&.strip
  end

  it "renders the total patients in 'All' row" do
    expect(patient_count_for_row("All")).to eq("120")
  end

  it "renders district patient count" do
    expect(patient_count_for_row("District 1")).to eq("120")
  end

  it "renders block patient count" do
    expect(patient_count_for_row("Block 1")).to eq("120")
  end

  it "renders facility patient counts" do
    expect(patient_count_for_row("Facility 1")).to eq("50")
    expect(patient_count_for_row("Facility 2")).to eq("70")
  end

  it "renders facilities subtotal patient count" do
    expect(patient_count_for_row("Facilities subtotal")).to eq("120")
  end

  it "renders drug headers and consumption values" do
    expect(rendered).to include("Hypertension Drugs")

    table_text = doc.text
    expect(table_text).to include("12")
    expect(table_text).to include("5")
    expect(table_text).to include("7")
  end
end
