require "rails_helper"

RSpec.describe DrugStocksReportExporter do
  it "renders the csv" do
    protocol = create(:protocol, :with_tracked_drugs)
    facility_group = create(:facility_group, protocol: protocol)
    facility = create(:facility, facility_group: facility_group)
    query = DrugStocksQuery.new(facilities: [facility], for_end_of_month: Date.current.end_of_month)
    stocks_by_rxnorm = {
      "329528" => {in_stock: 10000, received: 2000},
      "329526" => {in_stock: 20000, received: 2000},
      "316764" => {in_stock: 10000, received: 2000},
      "316765" => {in_stock: 20000, received: 2000},
      "979467" => {in_stock: 10000, received: 2000}
    }

    stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
      protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
      create(:drug_stock,
        facility: facility,
        protocol_drug: protocol_drug,
        in_stock: drug_stock[:in_stock],
        received: drug_stock[:received])
    end

    timestamp = ["Report last updated at:", query.drug_stocks_report.fetch(:last_updated_at)]
    headers_row_1 = [
      nil,
      "ARB Tablets",
      nil, nil, nil,
      "CCB Tablets",
      nil, nil,
      "Diuretic Tablets",
      nil, nil
    ]

    headers_row_2 = [
      "Facilities",
      "Losartan 50 mg",
      "Telmisartan 40 mg",
      "Telmisartan 80 mg",
      "Patient days",
      "Amlodipine 5 mg",
      "Amlodipine 10 mg",
      "Patient days",
      "Chlorthalidone 12.5 mg",
      "Hydrochlorothiazide 25 mg",
      "Patient days"
    ]

    totals_row = [
      "All",
      10000, 10000, 20000, "<patient days>",
      10000, 20000, "<patient days>",
      nil, nil, nil
    ]

    facility_rows = [
      facility.name,
      10000, 10000, 20000, "<patient days>",
      10000, 20000, "<patient days>",
      nil, nil, nil
    ]

    csv = described_class.csv(query)
    expected_csv =
      timestamp.to_csv +
      headers_row_1.to_csv +
      headers_row_2.to_csv +
      totals_row.to_csv +
      facility_rows.to_csv

    expect(csv).to eq(expected_csv)
  end
end
