require "rails_helper"

RSpec.describe DrugStocksQuery do
  let!(:state) { "Punjab" }
  let!(:protocol) { create(:protocol, :with_tracked_drugs) }
  let!(:facility_group) { create(:facility_group, protocol: protocol) }
  let!(:facility) { create(:facility, facility_group: facility_group, state: state) }
  let!(:user) { create(:admin, :manager, :with_access, resource: facility_group) }
  let!(:patients) { create_list(:patient, 10, registration_facility: facility, registration_user: user) }
  let!(:for_end_of_month) { Date.today.end_of_month }
  let!(:drug_category) { "hypertension_ccb" }
  let!(:stocks_by_rxnorm) {
    {"329528" => 10000, "329526" => 20000, "316764" => 10000, "316765" => 20000,
      "979467" => 10000, "316049" => 10000, "331132" => 10000}
  }
  let!(:drug_stocks) {
    stocks_by_rxnorm.map do |(rxnorm_code, in_stock)|
      protocol_drug = protocol.protocol_drugs.find_by(rxnorm_code: rxnorm_code)
      create(:drug_stock, user: user, facility: facility, protocol_drug: protocol_drug, in_stock: in_stock)
    end
  }
  let!(:punjab_drug_stock_config) {
    {"load_coefficient" => 1,
      "drug_categories" =>
        {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
          "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
          "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access
  }

  describe "#drug_stock_for_facility" do
    before do
      allow_any_instance_of(Reports::PatientDaysCalculation).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "something" do
      instance = described_class.new(facilities: [facility], for_end_of_month: for_end_of_month)
      result = instance.drug_stock_for_facility(facility, drug_stocks)
      expected_drug_stocks = drug_stocks.select {|drug_stock| %w[329528 329526].include? drug_stock.protocol_drug.rxnorm_code}
      expect(result["hypertension_ccb"][:drug_stocks].values).to match_array(expected_drug_stocks)
      expect(result["hypertension_ccb"][:patient_count]).to eq(patients.count)
      expect(result["hypertension_ccb"][:patient_days]).to eq(3714)
    end
  end
  # test #drug_stock_for_facility, mocking calculation, don't ignore params
  # test all early returns
  # structural test for data structure being returned

  # test #report_for_facilities, ensure all facilities are in report even if patient_count is nil

  # test #drug_stocks

  # test #totals, mocking calculation, don't ignore params
  # test totalling calculations
  # test early exists

  # test #cache_key
end