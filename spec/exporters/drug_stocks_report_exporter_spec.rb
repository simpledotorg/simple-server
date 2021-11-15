require "rails_helper"

RSpec.describe DrugStocksReportExporter do
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

    let(:timestamp) { ["Report last updated at:", Time.now] }

    before do
      facilities.each do |facility|
        stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
          protocol_drug = protocol.protocol_drugs.find_by!(rxnorm_code: rxnorm_code)
          create(:drug_stock,
            facility: facility,
            protocol_drug: protocol_drug,
            in_stock: drug_stock[:in_stock],
            received: drug_stock[:received])
        end
        create_list(:patient, 2, assigned_facility: facility)
      end

      stocks_by_rxnorm.map do |(rxnorm_code, drug_stock)|
        protocol_drug = protocol.protocol_drugs.find_by!(rxnorm_code: rxnorm_code)
        create(:drug_stock,
          region: facility_group.region,
          protocol_drug: protocol_drug,
          in_stock: drug_stock[:in_stock],
          received: drug_stock[:received])
      end
    end

    def refresh_views
      RefreshReportingViews.new.refresh_v2
    end

    it "renders the csv" do
      allow(CountryConfig.current).to receive(:fetch).with(:custom_drug_category_order, []).and_return([])

      headers_row_1 = [
        nil, nil, nil, nil,
        "ARB Tablets",
        nil, nil, nil,
        "CCB Tablets",
        nil, nil,
        "Diuretic Tablets",
        nil, nil
      ]

      headers_row_2 = [
        "Facilities",
        "Facility type",
        "Facility size",
        "Block",
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
        "All", "", "", "",
        30000, 30000, 60000, 121621,
        30000, 60000, 26785,
        nil, nil, nil
      ]

      district_warehouse_row = [
        "District Warehouse", "", "", "",
        10000, 10000, 20000, 40540,
        10000, 20000, 8928,
        nil, nil, nil
      ]

      facility_1_row =
        [facilities.first.name,
          facilities.first.facility_type,
          facilities.first.localized_facility_size,
          facilities.first.zone,
          10000, 10000, 20000, 81081,
          10000, 20000, 17857,
          nil, nil, nil]

      facility_2_row =
        [facilities.second.name,
          facilities.second.facility_type,
          facilities.second.localized_facility_size,
          facilities.second.zone,
          10000, 10000, 20000, 81081,
          10000, 20000, 17857,
          nil, nil, nil]
      refresh_views

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
        "CCB Tablets",
        nil, nil,
        "ARB Tablets",
        nil, nil, nil,
        "Diuretic Tablets",
        nil, nil
      ]

      headers_row_2 = [
        "Facilities",
        "Facility type",
        "Facility size",
        "Block",
        "Amlodipine 5 mg",
        "Amlodipine 10 mg",
        "Patient days",
        "Losartan 50 mg",
        "Telmisartan 40 mg",
        "Telmisartan 80 mg",
        "Patient days",
        "Chlorthalidone 12.5 mg",
        "Hydrochlorothiazide 25 mg",
        "Patient days"
      ]

      totals_row = [
        "All", "", "", "",
        30000, 60000, 26785,
        30000, 30000, 60000, 121621,
        nil, nil, nil
      ]

      district_warehouse_row = [
        "District Warehouse", "", "", "",
        10000, 20000, 8928,
        10000, 10000, 20000, 40540,
        nil, nil, nil
      ]

      facility_1_row =
        [facilities.first.name,
          facilities.first.facility_type,
          facilities.first.localized_facility_size,
          facilities.first.zone,
          10000, 20000, 17857,
          10000, 10000, 20000, 81081,
          nil, nil, nil]

      facility_2_row =
        [facilities.second.name,
          facilities.second.facility_type,
          facilities.second.localized_facility_size,
          facilities.second.zone,
          10000, 20000, 17857,
          10000, 10000, 20000, 81081,
          nil, nil, nil]
      refresh_views

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
