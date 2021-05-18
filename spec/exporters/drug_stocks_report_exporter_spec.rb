require "rails_helper"

RSpec.describe DrugStocksReportExporter do
  it "renders the csv" do
    protocol = create(:protocol, :with_tracked_drugs)
    facility_group = create(:facility_group, protocol: protocol)
    facility = create(:facility, facility_group: facility_group)
    query = DrugStocksQuery.new(facilities: [facility], for_end_of_month: Date.current.end_of_month)

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
      *[nil] * 10
    ]

    csv = described_class.csv(query)
    expect(csv).to eq(headers_row_1.to_csv + headers_row_2.to_csv + totals_row.to_csv)
  end
end
