require "rails_helper"

RSpec.describe Reports::PatientDaysCalculation, type: :model do
  describe "#stocks_on_hand works when" do
    let(:state) { "Punjab" }
    let(:protocol) { FactoryBot.create(:protocol, :with_tracked_drugs) }
    let(:facility_group) { FactoryBot.create(:facility_group, protocol: protocol) }
    let(:facility) { FactoryBot.create(:facility, facility_group: facility_group, state: state) }
    let(:drug_category) { "hypertension_ccb" }
    let(:stocks_by_rxnorm) {
      {'329528' => 10000, '329526' => 20000, '316764' => 10000, '316765' => 20000,
        '979467' => 10000, '316049' => 10000, '331132' => 10000} }
    let(:punjab_drug_stock_config) {
      {"load_coefficient" => 1,
        "drug_categories" =>
          {"hypertension_ccb" => {"new_patient_coefficient" => 1.4, "329528" => 1.2, "329526" => 2},
            "hypertension_arb" => {"new_patient_coefficient" => 0.37, "316764" => 1, "316765" => 2, "979467" => 1},
            "hypertension_diuretic" => {"new_patient_coefficient" => 0.06, "316049" => 1, "331132" => 1}}}.with_indifferent_access }
    let(:patient_count) { 10000 }

    before do
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(punjab_drug_stock_config)
    end

    it "has all drug stocks, and protocol and formula are cohesive" do
      result = described_class.new(state, protocol, drug_category, stocks_by_rxnorm, patient_count).stocks_on_hand
      expect(result).to match_array [
        {protocol_drug: protocol.protocol_drugs.find_by(rxnorm_code: "329528"),
         in_stock: 10000,
         coefficient: 1.2,
         stock_on_hand: 12000},
        {protocol_drug: protocol.protocol_drugs.find_by(rxnorm_code: "329526"),
         in_stock: 20000,
         coefficient: 2,
         stock_on_hand: 40000}
      ]
    end

    it "drug in protocol is not in formula" do
      FactoryBot.create(:protocol_drug, protocol: protocol, drug_category: drug_category, stock_tracked: true)
      result = described_class.new(state, protocol, drug_category, stocks_by_rxnorm, patient_count).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array ["329528", "329526"]
    end

    it "drug not in protocol is in formula" do
      drug_stock_config = punjab_drug_stock_config
      drug_stock_config["drug_categories"]["hypertension_ccb"] = {
        "new_patient_coefficient" => 1.4,
         "329528" => 1.2,
         "329526" => 2,
         "unknown_rx_norm" => 19
      }.with_indifferent_access
      allow_any_instance_of(described_class).to receive(:patient_days_coefficients).and_return(drug_stock_config)
      result = described_class.new(state, protocol, drug_category, stocks_by_rxnorm, patient_count).stocks_on_hand
      expect(result.map { |stock_on_hand| stock_on_hand[:protocol_drug].rxnorm_code }).to match_array ["329528", "329526"]
    end

    pending it "stock not available for an rxnorm" do

    end

    pending it "stock not available for all drugs" do

    end

    pending it "stock is 0" do

    end

    pending it "no formula for a state" do

    end

  end
  # stocks on hand

  # calculate
  # happy path [verify coefficients calculation]
  # patient count is nil
  # patient count is 0
  # patient days calculation
  # sentry
  # expect(result[:patient_count]).to eq patient_count
  # expect(result[:load_coefficient]).to eq 1
  # expect(result[:new_patient_coefficient]).to eq 1.4
  # expect(result[:estimated_patients]).to eq 14000
  # expect(result[:patient_days]).to eq ((10000*1 + 20000*2)/14000).floor

  # patient_days_coefficients
  # sbx, production
  # with and without state in config
end