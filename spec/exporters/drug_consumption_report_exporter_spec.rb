require "rails_helper"

RSpec.describe DrugConsumptionReportExporter do
  around do |example|
    Timecop.freeze do
      I18n.with_locale(:en_IN) do
        example.run
      end
    end
  end

  context "exports the csv" do
    let(:protocol) { create(:protocol, :with_tracked_drugs) }
    let(:facility_group) { create(:facility_group, protocol: protocol, state: "Punjab") }
    let(:facilities) { create_list(:facility, 2, facility_group: facility_group) }
    let(:query) {
      DrugStocksQuery.new(facilities: facilities,
                          for_end_of_month: Date.current.end_of_month)
    }

    let(:stocks_by_rxnorm) {
      {
        "329528" => {in_stock: 10000, received: 2000, redistributed: 0},
        "329526" => {in_stock: 20000, received: 2000, redistributed: 0},
        "316764" => {in_stock: 10000, received: 2000, redistributed: 0},
        "316765" => {in_stock: 20000, received: 2000, redistributed: nil},
        "979467" => {in_stock: 10000, received: 2000, redistributed: nil}
      }
    }

    let(:previous_month_stocks_by_rxnorm) {
      {
        "329528" => {in_stock: 8000},
        "329526" => {in_stock: 15000},
        "316764" => {in_stock: 8000},
        "316765" => {in_stock: 17000},
        "979467" => {in_stock: 9000}
      }
    }

    let(:timestamp) { ["Report last updated at:", Time.now] }

    before do
      stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
        protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
        create(:drug_stock,
          region: facility_group.region,
          protocol_drug: protocol_drug,
          in_stock: drug_stock[:in_stock],
          received: drug_stock[:received],
          redistributed: drug_stock[:redistributed])
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
          region: facility_group.region,
          protocol_drug: protocol_drug,
          in_stock: drug_stock[:in_stock],
          for_end_of_month: (Date.today - 1.month).end_of_month)
        create(:drug_stock,
          facility: facilities.first,
          protocol_drug: protocol_drug,
          in_stock: drug_stock[:in_stock],
          for_end_of_month: (Date.today - 1.month).end_of_month)
      end
    end

    it "renders the csv" do
      allow(CountryConfig.current).to receive(:fetch).with(:custom_drug_category_order, []).and_return([])

      headers_row_1 = [
        nil, nil, nil, nil,
        "ARB Tablets", nil, nil,
        "CCB Tablets", nil,
        "Diuretic Tablets", nil,
        "Overall in base doses", nil, nil
      ]

      headers_row_2 = [
        "Facilities",
        "Facility type",
        "Facility size",
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
        "All", "", "", "",
        2000, 0, -2000,
        0, -6000,
        "?", "?",
        -2000, -12000, "?"
      ]

      district_warehouse_row = [
        "District Warehouse", "", "", "",
        1000, 0, -1000,
        0, -3000,
        "?", "?",
        -1000, -6000, "?"
      ]

      facility_1_row =
        [facilities.first.name,
          facilities.first.facility_type,
          facilities.first.localized_facility_size,
          facilities.first.zone,
          1000, 0, -1000,
          0, -3000,
          "?", "?",
          -1000, -6000, "?"]

      facility_2_row =
        [facilities.second.name,
          facilities.second.facility_type,
          facilities.second.localized_facility_size,
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
        district_warehouse_row.to_csv +
        facility_1_row.to_csv +
        facility_2_row.to_csv

      expect(csv).to eq(expected_csv)
    end

    it "renders the csv in custom category order" do
      allow(CountryConfig.current).to receive(:fetch)
        .with(:custom_drug_category_order, [])
        .and_return(["hypertension_ccb", "hypertension_arb", "hypertension_diuretic"])

      headers_row_1 = [
        nil, nil, nil, nil,
        "CCB Tablets", nil,
        "ARB Tablets", nil, nil,
        "Diuretic Tablets", nil,
        "Overall in base doses", nil, nil
      ]

      headers_row_2 = [
        "Facilities",
        "Facility type",
        "Facility size",
        "Block",
        "Amlodipine 5 mg",
        "Amlodipine 10 mg",
        "Losartan 50 mg",
        "Telmisartan 40 mg",
        "Telmisartan 80 mg",
        "Chlorthalidone 12.5 mg",
        "Hydrochlorothiazide 25 mg",
        "CCB base doses",
        "ARB base doses",
        "Diuretic base doses"
      ]

      totals_row = [
        "All", "", "", "",
        0, -6000,
        2000, 0, -2000,
        "?", "?",
        -12000, -2000, "?"
      ]

      district_warehouse_row = [
        "District Warehouse", "", "", "",
        0, -3000,
        1000, 0, -1000,
        "?", "?",
        -6000, -1000, "?"
      ]

      facility_1_row =
        [facilities.first.name,
          facilities.first.facility_type,
          facilities.first.localized_facility_size,
          facilities.first.zone,
          0, -3000,
          1000, 0, -1000,
          "?", "?",
          -6000, -1000, "?"]

      facility_2_row =
        [facilities.second.name,
          facilities.second.facility_type,
          facilities.first.localized_facility_size,
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
        district_warehouse_row.to_csv +
        facility_1_row.to_csv +
        facility_2_row.to_csv

      expect(csv).to eq(expected_csv)
    end
  end
end
