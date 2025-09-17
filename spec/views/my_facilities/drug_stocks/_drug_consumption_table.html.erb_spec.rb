require "rails_helper"

RSpec.describe "my_facilities/drug_stocks/_drug_consumption_table.html.erb", type: :view do
  let(:region) { instance_double("Region", id: 123) }
  let(:facility1) { instance_double("Facility", id: 1, name: "Facility 1", region: region) }
  let(:facility2) { instance_double("Facility", id: 2, name: "Facility 2", region: region) }
  let(:drug) { instance_double("ProtocolDrug", id: 1, name: "Amlodipine", dosage: "5mg") }
  let(:facility1_report) do
    {
      hypertension: {drug => {consumed: 5}, :base_doses => {total: 5}},
      drugs: [
        {consumed: 5, base_doses: 5}
      ]
    }
  end

  let(:facility2_report) do
    {
      hypertension: {drug => {consumed: 7}, :base_doses => {total: 7}},
      drugs: [
        {consumed: 7, base_doses: 7}
      ]
    }
  end

  let(:report) do
    {
      total_patient_count: 120,
      district_patient_count: 120,
      facilities_total_patient_count: 120,
      patient_count_by_block_id: {1 => 120},
      patient_count_by_facility_id: {1 => 50, 2 => 70},
      total_drug_consumption: {hypertension: {drug => {consumed: 10}, :base_doses => {total: 10}}},
      district_drug_consumption: {hypertension: {drug => {consumed: 10}, :base_doses => {total: 10}}},
      drug_consumption_by_block_id: {1 => {hypertension: {drug => {consumed: 10}, :base_doses => {total: 10}}}},
      facilities_total_drug_consumption: {hypertension: {drug => {consumed: 10}, :base_doses => {total: 10}}},
      drug_consumption_by_facility_id: {
        1 => facility1_report,
        2 => facility2_report
      },
      drugs: [
        {consumed: 5, base_doses: 5},
        {consumed: 7, base_doses: 7}
      ]
    }
  end

  before do
    assign(:report, report)
    assign(:facilities, [facility1, facility2])
    assign(:drugs_by_category, {hypertension: [drug]})

    allow(view).to receive(:protocol_drug_labels).and_return(
      {hypertension: {full: "Hypertension Drugs", short: "HTN"}}
    )
    allow(view).to receive(:can_view_all_districts_nav?).and_return(true)
    allow(view).to receive(:t).and_return("Translated text")

    def view.tooltip_for(*)
      "tooltip text"
    end
  end

  it "renders the total patients in 'All' row" do
    render
    expect(rendered).to match(/120/)
  end

  it "renders drug consumption values" do
    render
    expect(rendered).to match(/10/) # total consumption
    expect(rendered).to match(/5/) # facility1 consumption
    expect(rendered).to match(/7/) # facility2 consumption
  end
end
