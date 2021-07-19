require "rails_helper"

RSpec.describe DrugConsumptionReportExporter do
  around do |example|
    I18n.with_locale(:en_IN) do
      example.run
    end
  end

  it "renders the csv" do
    protocol = create(:protocol, :with_tracked_drugs)
    facility_group = create(:facility_group, protocol: protocol, state: "Punjab")
    facilities = create_list(:facility, 2, facility_group: facility_group)
    query = DrugStocksQuery.new(facilities: facilities,
                                for_end_of_month: Date.current.end_of_month,
                                include_block_report: true)

    stocks_by_rxnorm = {
      "329528" => {in_stock: 10000, received: 2000, redistributed: 0},
      "329526" => {in_stock: 20000, received: 2000, redistributed: 0},
      "316764" => {in_stock: 10000, received: 2000, redistributed: 0},
      "316765" => {in_stock: 20000, received: 2000, redistributed: 0},
      "979467" => {in_stock: 10000, received: 2000, redistributed: 0}
    }

    previous_month_stocks_by_rxnorm =
      {"329528" => {in_stock: 8000},
       "329526" => {in_stock: 15000},
       "316764" => {in_stock: 8000},
       "316765" => {in_stock: 17000},
       "979467" => {in_stock: 9000}}

    stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
      protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
      create(:drug_stock,
        facility: facilities.first,
        protocol_drug: protocol_drug,
        in_stock: drug_stock[:in_stock],
        received: drug_stock[:received],
        redistributed: drug_stock[:redistributed])
    end

    previous_month_stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
      protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
      create(:drug_stock,
        facility: facilities.first,
        protocol_drug: protocol_drug,
        in_stock: drug_stock[:in_stock],
        for_end_of_month: (Date.today - 1.month).end_of_month)
    end

    timestamp = ["Report last updated at:", query.drug_stocks_report.fetch(:last_updated_at)]
    headers_row_1 = [
      nil, nil,
      "ARB Tablets", nil, nil,
      "CCB Tablets", nil,
      "Diuretic Tablets", nil,
      "Overall in base doses", nil, nil
    ]

    headers_row_2 = [
      "Facilities",
      "Block",
      "Losartan 50 mg",
      "Telmisartan 40 mg",
      "Telmisartan 80 mg",
      "Amlodipine 5 mg",
      "Amlodipine 10 mg",
      "Chlorthalidone 12.5 mg",
      "Hydrochlorothiazide 25 mg",
      "ARB base doses",
      "CCB base doses",
      "Diuretic base doses"
    ]

    totals_row = [
      "All", "",
      1000, 0, -1000,
      0, -3000,
      "?", "?",
      -1000, -6000, "?"
    ]

    facility_1_row =
      [facilities.first.name,
        facilities.first.zone,
        1000, 0, -1000,
        0, -3000,
        "?", "?",
        -1000, -6000, "?"]

    facility_2_row =
      [facilities.second.name,
        facilities.second.zone,
        "?", "?", "?", "?",
        "?", "?",
        "?", "?",
        "?", "?"]

    csv = described_class.csv(query)
    expected_csv =
      timestamp.to_csv +
      headers_row_1.to_csv +
      headers_row_2.to_csv +
      totals_row.to_csv +
      facility_1_row.to_csv +
      facility_2_row.to_csv

    expect(csv).to eq(expected_csv)
  end
end
